/*
 * gstticapturesrc.c
 *
 * This file implements "ticapturesrc" element.
 *
 * Example usage:
 *     gst-launch ticapturesrc ! tidisplaysink2 -v
 *
 * Original Author:
 *     Brijesh Singh, Texas Instruments, Inc.
 *
 * Copyright (C) 2010-2011 Texas Instruments Incorporated - http://www.ti.com/
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation version 2.1 of the License.
 *
 * This program is distributed #as is# WITHOUT ANY WARRANTY of any kind,
 * whether express or implied; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 */

#include <gst/gst.h>
#include <string.h>
#include <gst/gstmarshal.h>
//#include <linux/videodev.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "gstticapturesrc.h"
#include "gstticommonutils.h"

/* define property defaults */
#define     DEFAULT_DEVICE          "/dev/video0"
#define     DEFAULT_MMAP_BUFFER      FALSE
#define     DEFAULT_PEER_ALLOC       TRUE
#define     DEFAULT_NUM_BUFS         3
#define     MAX_NUM_BUFS             8
#define     MIN_NUM_BUFS             2
#define     DEFAULT_FRAMERATE_NUM    30000
#define     DEFAULT_FRAMERATE_DEN    1001

/* define platform specific defaults */
#if defined(Platform_dm6467) || defined(Platform_dm6467t)
    #define DEFAULT_CAPTURE_INPUT  "component"
    #define SRC_CAPS    GST_VIDEO_CAPS_YUV("NV12")
    #define CAPTURE_COLORSPACE ColorSpace_YUV420PSEMI
    #define DEFAULT_VIDEO_STD   "720p"
#elif defined(Platform_dm368)
    #define DEFAULT_CAPTURE_INPUT   "camera"
    #define SRC_CAPS    GST_VIDEO_CAPS_YUV("NV12")
    #define CAPTURE_COLORSPACE ColorSpace_YUV420PSEMI
    #define DEFAULT_VIDEO_STD   "720p"
#else
    #define     DEFAULT_CAPTURE_INPUT        "composite"
    #define SRC_CAPS    GST_VIDEO_CAPS_YUV("UYVY")
    #define CAPTURE_COLORSPACE ColorSpace_UYVY
    #define DEFAULT_VIDEO_STD   "ntsc"
#endif

static void *parent_class;

/* Define src and src pad capabilities. */
static GstStaticPadTemplate src_factory = GST_STATIC_PAD_TEMPLATE(
  "src",
  GST_PAD_SRC,
  GST_PAD_ALWAYS,
  GST_STATIC_CAPS
  (
   SRC_CAPS
  )
);

enum
{
  PROP_0,
  PROP_DEVICE,
  PROP_NUMBUFS,
  PROP_MMAP_BUFFER,
  PROP_PEER_ALLOC,
  PROP_DEVICE_FD,
  PROP_CAPTURE_INPUT,
  PROP_VIDEO_STD
};

/* Declare variable used to categorize GST_LOG output */
GST_DEBUG_CATEGORY_STATIC (gst_ticapturesrc_debug);
#define GST_CAT_DEFAULT gst_ticapturesrc_debug

static gboolean
alloc_bufTab(GstTICaptureSrc *src)
{
    BufferGfx_Attrs gfx  = BufferGfx_Attrs_DEFAULT;
    int size;

    gfx.dim.width = src->width;
    gfx.dim.height = src->height;
    gfx.colorSpace = src->cAttrs.colorSpace;

    gfx.dim.lineLength = BufferGfx_calcLineLength(src->width, gfx.colorSpace);

    #if defined(Platform_dm365) || defined(Platform_dm368)
        gfx.dim.lineLength = Dmai_roundUp(gfx.dim.lineLength, 32);
    #endif

    size = gst_ti_calc_buffer_size(gfx.dim.width, gfx.dim.height, gfx.dim.lineLength, gfx.colorSpace);
		GST_INFO(
				"bufsize: %d %ldx%ld linesize %ld", 
				size,
				gfx.dim.width, gfx.dim.height, gfx.dim.lineLength 
				);

    gfx.bAttrs.useMask = gst_tidmaibuffer_VIDEOSRC_FREE;
    src->cAttrs.numBufs = src->numbufs;
    src->hBufTab = gst_tidmaibuftab_new(src->cAttrs.numBufs, size,
        BufferGfx_getBufferAttrs(&gfx));
    gst_tidmaibuftab_set_blocking(src->hBufTab, FALSE);

    return TRUE;
}

static gchar*
dmai_capture_input_str (int id)
{
    if (id == Capture_Input_SVIDEO)
        return "svideo";

    if (id == Capture_Input_COMPOSITE)
        return "composite";

    if (id == Capture_Input_COMPONENT)
        return "component";

    if (id == Capture_Input_CAMERA)
        return "camera";

    return "auto";
}

static int
dmai_capture_input (const gchar* str)
{
    if (!strcmp(str, "svideo"))
        return Capture_Input_SVIDEO;

    if (!strcmp(str, "composite"))
        return Capture_Input_COMPOSITE;

    if (!strcmp(str, "component"))
        return Capture_Input_COMPONENT;

    if (!strcmp(str, "camera"))
        return Capture_Input_CAMERA;

    return -1;
}

static int
dmai_video_std (const gchar* str)
{
    if (!strcmp(str, "ntsc"))
        return VideoStd_D1_NTSC;

    if (!strcmp(str, "pal"))
        return VideoStd_D1_PAL;

    if (!strcmp(str, "480p"))
        return VideoStd_480P;

    if (!strcmp(str, "720p"))
        return VideoStd_720P_60;

    if (!strcmp(str, "1080i"))
        return VideoStd_1080I_30;

    if (!strcmp(str, "1080p"))
        return VideoStd_1080P_30;

    return VideoStd_AUTO;
}

static gboolean
capture_create(GstTICaptureSrc *src)
{
    GST_LOG_OBJECT(src,"capture_create begin");

    if (src->hCapture == NULL) {

        if (src->mmap_buffer == FALSE) {
            if (!alloc_bufTab(src)) {
                GST_ELEMENT_ERROR(src, RESOURCE, FAILED,
                ("Failed to allocate buffer\n"), (NULL));
                return FALSE;
            }
        }
        src->hCapture = Capture_create(GST_TIDMAIBUFTAB_BUFTAB(src->hBufTab),
                             &src->cAttrs);

        if (src->hCapture == NULL) {
            GST_ELEMENT_ERROR(src, RESOURCE, FAILED,
            ("Failed to create capture handle\n"), (NULL));
            return FALSE;
        }
    }

    g_object_set(src, "device", src->cAttrs.captureDevice, NULL);
    g_object_set(src, "capture-input", dmai_capture_input_str(src->cAttrs.videoInput), NULL);
    g_object_set(src, "queue-size", src->cAttrs.numBufs, NULL);
    g_object_set(src, "mmap-buffer", GST_TIDMAIBUFTAB_BUFTAB(src->hBufTab) ? FALSE : TRUE, NULL);

    GST_LOG_OBJECT(src,"capture_create end");
    return TRUE;
}

static gboolean
setcaps(GstBaseSrc *base, GstCaps *caps)
{
    GstTICaptureSrc *src = (GstTICaptureSrc *)base;
    GstStructure *structure;
    guint32             fourcc;
    const gchar  *mime;
    Int32   width, height;

    /* Print value of the negotiated source pad caps */
    char    *string;
    string = gst_caps_to_string(caps);
    GST_LOG("negotiated caps: %s", string);
    g_free(string);

    GST_LOG_OBJECT(src,"setcaps begin");
    structure = gst_caps_get_structure(caps, 0);
    mime      = gst_structure_get_name(structure);

    /* Save values of negotiated caps: fourcc, width, height, framerate */
    gst_structure_get_int(structure, "width", &src->width);
    gst_structure_get_int(structure, "height", &src->height);
    gst_structure_get_fraction(structure, "framerate", &src->fps_n, &src->fps_d);
    gst_value_set_fraction(&src->framerate, src->fps_n, src->fps_d);
    if (!strncmp(mime, "video/x-raw-yuv", 15)) {
        gst_structure_get_fourcc(structure, "format", &fourcc);

        switch (fourcc) {
            case GST_MAKE_FOURCC('U', 'Y', 'V', 'Y'):
                src->cAttrs.colorSpace = ColorSpace_UYVY;
                break;
            case GST_MAKE_FOURCC('N', 'V', '1', '2'):
                src->cAttrs.colorSpace = ColorSpace_YUV420PSEMI;
                break;
            default:
                GST_ERROR("unsupported fourcc");
                return FALSE;
        }
    }

    if (src->width <=1 && src->height <=1) {
        VideoStd_getResolution(src->cAttrs.videoStd, &width, &height);
        src->width = width;
        src->height = height;
    }
		src->width = 720;
		src->height = 576;
    GST_WARNING("force video size to %dx%d", src->width, src->height);

    GST_LOG_OBJECT(src,"setcaps end");
    return TRUE;
}

static gboolean
start(GstBaseSrc *base)
{
    GstTICaptureSrc *src = (GstTICaptureSrc *)base;

    GST_LOG("start begin");

    src->offset = 0;
//    gst_value_set_fraction(&src->framerate,DEFAULT_FRAMERATE_NUM, DEFAULT_FRAMERATE_DEN);
    src->cAttrs.numBufs = src->numbufs;
    src->cAttrs.captureDevice = src->device;
    src->cAttrs.videoInput = dmai_capture_input(src->capture_input);
    src->cAttrs.videoStd = dmai_video_std(src->video_standard);

    /* if we have a framerate pre-calculate duration */
    if (gst_value_get_fraction_numerator(&src->framerate)>0 &&
        gst_value_get_fraction_denominator(&src->framerate)>0) {
            src->duration = gst_util_uint64_scale_int (GST_SECOND,
                gst_value_get_fraction_denominator(&src->framerate),
                gst_value_get_fraction_numerator(&src->framerate));
    }
    else {
        src->duration = GST_CLOCK_TIME_NONE;
    }

    GST_LOG("start end");
    return TRUE;
}

static gboolean
stop(GstBaseSrc *base)
{
    GstTICaptureSrc *src = (GstTICaptureSrc *)base;

    GST_LOG_OBJECT(src,"stop begin");
    if (src->hCapture) {
        Capture_delete(src->hCapture);
    }

    if (src->hBufTab) {
           gst_tidmaibuftab_unref(src->hBufTab);
    }

    GST_LOG_OBJECT(src,"stop end");
    return TRUE;
}

void
capture_buffer_finalize(void *args, GstBuffer* buf)
{
    GstTICaptureSrc *src = (GstTICaptureSrc *)args;
    Buffer_Handle   hDstBuf = NULL;

    hDstBuf = GST_TIDMAIBUFFERTRANSPORT_DMAIBUF(buf);

    if (src->hCapture) {
        if (Capture_put(src->hCapture, hDstBuf)) {
            GST_ELEMENT_ERROR(src, RESOURCE, FAILED,
            ("Failed to allocate buffer\n"), (NULL));
            return;
        }
    }
}

static GstFlowReturn
create(GstPushSrc *base, GstBuffer **buf)
{
    GstTICaptureSrc *src = (GstTICaptureSrc *)base;
    Buffer_Handle       hDstBuf;
    GstBuffer   *outBuf;
    gint    ret = GST_FLOW_OK;
    BufferGfx_Attrs  gfxAttrs = BufferGfx_Attrs_DEFAULT;
    Int32   width, height;

    GST_LOG("create begin");

    /* create capture device */
    if (src->hCapture == NULL) {

        /* set framerate based on video standard */
        switch(dmai_video_std(src->video_standard)) {
            case VideoStd_D1_NTSC:
                    gst_value_set_fraction(&src->framerate,30000,1001);
                break;
            case VideoStd_D1_PAL:
                    gst_value_set_fraction(&src->framerate,25,1);
                break;
            default:
                    gst_value_set_fraction(&src->framerate,30,1);
                break;
        }

        /* set width & height based on video standard */

        src->cAttrs.videoStd = dmai_video_std(src->video_standard);

        VideoStd_getResolution(src->cAttrs.videoStd, &width, &height);
				width = 720;
				height = 576;
				GST_WARNING("force video size to %dx%d", src->width, src->height);

        src->width = width;
        src->height = height;
        
        gfxAttrs.dim.height = src->height;
        gfxAttrs.dim.width = src->width;
        src->cAttrs.captureDimension = &gfxAttrs.dim;

        if (!capture_create(src))
            return GST_FLOW_ERROR;
    }

    /* Get buffer from driver */
    if (Capture_get(src->hCapture, &hDstBuf)) {
        GST_ELEMENT_ERROR(src, RESOURCE, FAILED,
        ("Failed to allocate buffer\n"), (NULL));
        return GST_FLOW_ERROR;
    }

    /* Create a DMAI transport buffer object to carry a DMAI buffer to
     * the source pad.  The transport buffer knows how to release the
     * buffer for re-use in this element when the source pad calls
     * gst_buffer_unref().
     */
    outBuf = gst_tidmaibuffertransport_new(hDstBuf, src->hBufTab, capture_buffer_finalize, (void*)src);
    gst_buffer_set_data(outBuf, GST_BUFFER_DATA(outBuf), Buffer_getSize(hDstBuf));

    *buf = outBuf;

    /* set buffer metadata */
    if (G_LIKELY (ret == GST_FLOW_OK && *buf)) {
        GstClock *clock;
        GstClockTime timestamp;

        GST_BUFFER_OFFSET (*buf) = src->offset++;
        GST_BUFFER_OFFSET_END (*buf) = src->offset;

        /* timestamps, LOCK to get clock and base time. */
        GST_OBJECT_LOCK (src);
        if ((clock = GST_ELEMENT_CLOCK (src))) {
            /* we have a clock, get base time and ref clock */
            timestamp = GST_ELEMENT (src)->base_time;
            gst_object_ref (clock);
        } else {
            /* no clock, can't set timestamps */
            timestamp = GST_CLOCK_TIME_NONE;
        }
        GST_OBJECT_UNLOCK (src);

        if (G_LIKELY (clock)) {
            /* the time now is the time of the clock minus the base time */
            timestamp = gst_clock_get_time (clock) - timestamp;
            gst_object_unref (clock);

            /* if we have a framerate adjust timestamp for frame latency */
            if (GST_CLOCK_TIME_IS_VALID (src->duration)) {
                if (timestamp > src->duration)
                    timestamp -= src->duration;
                else
                    timestamp = 0;
            }

        }

        /* FIXME: use the timestamp from the buffer itself! */
        GST_BUFFER_TIMESTAMP (*buf) = timestamp;
        GST_BUFFER_DURATION (*buf) = src->duration;
    }

    /* Create caps for buffer */
    GstCaps *mycaps;
    GstStructure        *structure;

    mycaps = gst_caps_new_empty();

    if (src->cAttrs.colorSpace == ColorSpace_UYVY) {
        structure = gst_structure_new( "video/x-raw-yuv",
            "format", GST_TYPE_FOURCC, GST_MAKE_FOURCC('U', 'Y', 'V', 'Y'),
            "framerate", GST_TYPE_FRACTION,
                gst_value_get_fraction_numerator(&src->framerate),
                gst_value_get_fraction_denominator(&src->framerate),
            "width", G_TYPE_INT,    src->width,
            "height", G_TYPE_INT,   src->height,
            (gchar*) NULL);

    }
    else if(src->cAttrs.colorSpace == ColorSpace_YUV420PSEMI) {
        structure = gst_structure_new( "video/x-raw-yuv",
            "format", GST_TYPE_FOURCC, GST_MAKE_FOURCC('N', 'V', '1', '2'),
            "framerate", GST_TYPE_FRACTION,
                gst_value_get_fraction_numerator(&src->framerate),
                gst_value_get_fraction_denominator(&src->framerate),
            "width", G_TYPE_INT,    src->width,
            "height", G_TYPE_INT,   src->height,
            (gchar*) NULL);
    }
    else {
        GST_ERROR("unsupported fourcc\n");
        return FALSE;
    }

    gst_caps_append_structure(mycaps, gst_structure_copy (structure));
    gst_structure_free(structure);
    gst_buffer_set_caps(*buf, mycaps);
    gst_caps_unref(mycaps);

		{
			static int fn;
			fn++;
			GST_INFO("capture frame %d", fn);
		}

    GST_LOG("create end");
    return GST_FLOW_OK;
}

static void
set_property(GObject *object, guint prop_id, const GValue *value,
    GParamSpec *pspec)
{
    GstTICaptureSrc *src = GST_TICAPTURESRC(object);

    GST_LOG_OBJECT(src,"set property begin");
    switch (prop_id) {
        case PROP_DEVICE:
            if (src->device) {
                g_free((gpointer)src->device);
            }
            src->device = (gchar*)g_malloc(strlen(g_value_get_string(value))
                + 1);
            strcpy((gchar*)src->device, g_value_get_string(value));
            break;
        case PROP_NUMBUFS:
            src->numbufs = g_value_get_int(value);
            break;
        case PROP_CAPTURE_INPUT:
            if (src->capture_input) {
                g_free((gpointer)src->capture_input);
            }
            src->capture_input = (gchar*)g_malloc(strlen(g_value_get_string(value))
                + 1);
            strcpy((gchar*)src->capture_input, g_value_get_string(value));
            break;
        case PROP_VIDEO_STD:
            if (src->video_standard) {
                g_free((gpointer)src->video_standard);
            }
            src->video_standard = (gchar*)g_malloc(strlen(g_value_get_string(value))
                + 1);
            strcpy((gchar*)src->video_standard, g_value_get_string(value));
            break;
        case PROP_MMAP_BUFFER:
            src->mmap_buffer = g_value_get_boolean(value);
            break;
        case PROP_PEER_ALLOC:
            src->peer_alloc = g_value_get_boolean(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }

    GST_LOG_OBJECT(src,"set property end");
}

static void
get_property(GObject *object, guint prop_id, GValue *value, GParamSpec *pspec)
{
    GstTICaptureSrc *src = GST_TICAPTURESRC(object);

    GST_LOG_OBJECT(src,"get property begin");

    switch (prop_id) {
        case PROP_DEVICE:
            g_value_set_string(value, src->device);
            break;
        case PROP_DEVICE_FD:
            g_value_set_int(value, src->fd);
            break;
        case PROP_VIDEO_STD:
            g_value_set_string(value, src->video_standard);
            break;
        case PROP_NUMBUFS:
            g_value_set_int(value, src->numbufs);
            break;
        case PROP_CAPTURE_INPUT:
            g_value_set_string(value, src->capture_input);
            break;
        case PROP_MMAP_BUFFER:
            g_value_set_boolean(value, src->mmap_buffer);
            break;
        case PROP_PEER_ALLOC:
            g_value_set_boolean(value, src->peer_alloc);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }

    GST_LOG_OBJECT(src,"get property end");
}

static void
ticapturesrc_class_init(GstTICaptureSrcClass *klass)
{
    GObjectClass     *gobject_class;
    GstElementClass  *gstelement_class;
    GstBaseSrcClass *gstbase_src_class;
    GstPushSrcClass *pushsrc_class;

    GST_LOG("class_init  begin");

    gobject_class       = G_OBJECT_CLASS(klass);
    gstelement_class    = GST_ELEMENT_CLASS(klass);
    gstbase_src_class   = GST_BASE_SRC_CLASS(klass);
    pushsrc_class       = GST_PUSH_SRC_CLASS (klass);

    gobject_class->set_property = set_property;
    gobject_class->get_property = get_property;

    parent_class = g_type_class_peek_parent (klass);

    g_object_class_install_property(gobject_class, PROP_DEVICE,
        g_param_spec_string("device", "Device",    "Device location",
        DEFAULT_DEVICE, G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_class_install_property(gobject_class, PROP_NUMBUFS,
        g_param_spec_int("queue-size", "Video driver queue size",
        "Number of buffers to be enqueud in the driver in streaming mod",
        MIN_NUM_BUFS, MAX_NUM_BUFS, DEFAULT_NUM_BUFS, G_PARAM_READWRITE ));

    g_object_class_install_property(gobject_class, PROP_CAPTURE_INPUT,
        g_param_spec_string("capture-input", "Capture input name",
        "Available Capture Input \n"
        "\t\t\tsvideo\n"
        "\t\t\tcomposite\n"
        "\t\t\tcomponent\n"
        "\t\t\tauto",
        DEFAULT_CAPTURE_INPUT, G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_class_install_property(gobject_class, PROP_MMAP_BUFFER,
        g_param_spec_boolean("mmap-buffer", "Driver buffer",
        "Use driver mapped buffers (i.e mmap) for capture",
        DEFAULT_MMAP_BUFFER, G_PARAM_READWRITE));

    g_object_class_install_property(gobject_class, PROP_DEVICE_FD,
        g_param_spec_int("device-fd", "File descriptor of the device",
        "File descriptor of the device"
        , -1, G_MAXINT, -1, G_PARAM_READABLE ));

    g_object_class_install_property(gobject_class, PROP_VIDEO_STD,
        g_param_spec_string("video-standard", "Capture Standard",
        "Available Display Standard \n"
        "\t\t\tntsc\n"
        "\t\t\tpal\n"
        "\t\t\t480p\n"
        "\t\t\t720p\n"
        "\t\t\t1080i\n"
        "\t\t\t1080p\n"
        "\t\t\tauto",
        DEFAULT_VIDEO_STD, G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    gstbase_src_class->set_caps = setcaps;
    gstbase_src_class->start = start;
    gstbase_src_class->stop = stop;
    gstbase_src_class->is_seekable = NULL;

    pushsrc_class->create = create;

    GST_LOG("class init end");
}

static void
ticapturesrc_base_init(void *gclass)
{
    static GstElementDetails element_details = {
        "Dmai based capture src",
        "Src/Video",
        "Capture video on TI OMAP and Davinci platform",
        "Brijesh Singh; Texas Instruments, Inc."
    };

    GstElementClass *element_class = GST_ELEMENT_CLASS(gclass);

    GST_LOG("base init begin");

    gst_element_class_add_pad_template(element_class,
    gst_static_pad_template_get (&src_factory));
    gst_element_class_set_details(element_class, &element_details);

    GST_LOG("base init end");
}

static void
init (GstTICaptureSrc *src, gpointer *data)
{
    GST_LOG_OBJECT(src,"init start");
    src->cAttrs = Capture_Attrs_DM365_DEFAULT;
    src->numbufs = DEFAULT_NUM_BUFS;
    src->mmap_buffer = DEFAULT_MMAP_BUFFER;
    src->peer_alloc = DEFAULT_PEER_ALLOC;
    src->cAttrs.colorSpace = CAPTURE_COLORSPACE;
    src->fd = -1;
    src->width = -1;
    src->height = -1;

    g_object_set(src, "device", DEFAULT_DEVICE, NULL);
    g_object_set(src, "capture-input", DEFAULT_CAPTURE_INPUT, NULL);
    g_object_set(src, "video-standard", DEFAULT_VIDEO_STD, NULL);
    GST_LOG_OBJECT(src,"init end");

    /* Initialize GValue members */
    memset(&src->framerate, 0, sizeof(GValue));
    g_value_init(&src->framerate, GST_TYPE_FRACTION);
    g_assert(GST_VALUE_HOLDS_FRACTION(&src->framerate));
    gst_value_set_fraction(&src->framerate, DEFAULT_FRAMERATE_NUM, DEFAULT_FRAMERATE_DEN);

}

GType
gst_ticapturesrc_get_type(void)
{
    static GType type;

    if (G_UNLIKELY(type == 0)) {
        GTypeInfo type_info = {
            sizeof(struct gst_ticapture_src_class),
            ticapturesrc_base_init,
            NULL,
            (GClassInitFunc) ticapturesrc_class_init,
            NULL,
            NULL,
            sizeof(GstTICaptureSrc),
            0,
            (GInstanceInitFunc)init
        };

        type = g_type_register_static(GST_TYPE_PUSH_SRC, "GstTICaptureSrc",
                &type_info, 0);

        /* Initialize GST_LOG for this object */
        GST_DEBUG_CATEGORY_INIT(gst_ticapturesrc_debug, "ticapturesrc", 0,
            "Video Capture src");
    }

    return type;
}


