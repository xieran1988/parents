/*
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


#ifndef __GST_TICAPTURESRC_H__
#define __GST_TICAPTURESRC_H__

#include <gst/gst.h>
#include <gst/base/gstbasesrc.h>
#include <gst/base/gstpushsrc.h>
#include <gst/video/video.h>
#include <ti/sdo/dmai/Capture.h>
#include <ti/sdo/dmai/BufferGfx.h>
#include <ti/sdo/dmai/VideoStd.h>

#include "gsttidmaibuftab.h"
#include "gsttidmaibuffertransport.h"

G_BEGIN_DECLS

#define GST_TYPE_TICAPTURESRC \
  (gst_ticapturesrc_get_type())
#define GST_TICAPTURESRC(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),GST_TYPE_TICAPTURESRC,GstTICaptureSrc))
#define GST_TICAPTURESRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass),GST_TYPE_TICAPTURESRC,GstTICaptureSrcClass))
#define GST_IS_TICAPTURESRC(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj),GST_TYPE_TICAPTURESRC))
#define GST_IS_TICAPTURESRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass),GST_TYPE_TICAPTURESRC))

struct gst_ticapture_src {
    GstPushSrc pushsrc;

    GstTIDmaiBufTab *hBufTab;
    Capture_Handle hCapture;
    Capture_Attrs   cAttrs;
    VideoStd_Type    videoStd;

    gchar *device, *capture_input, *video_standard;
    gint  numbufs, width, height, fd;
    gint fps_n, fps_d;
    GValue framerate;

    gboolean  mmap_buffer,peer_alloc; 
    guint64 offset, duration;    
};

struct gst_ticapture_src_class {
    GstPushSrcClass parent_class;
};

typedef struct gst_ticapture_src GstTICaptureSrc;
typedef struct gst_ticapture_src_class GstTICaptureSrcClass;

GType gst_ticapturesrc_get_type(void);

G_END_DECLS

#endif /* __GST_TICAPTURESRC_H__ */

/******************************************************************************
 * Custom ViM Settings for editing this file
 ******************************************************************************/
#if 0
 Tabs (use 4 spaces for indentation)
 vim:set tabstop=4:      /* Use 4 spaces for tabs          */
 vim:set shiftwidth=4:   /* Use 4 spaces for >> operations */
 vim:set expandtab:      /* Expand tabs into white spaces  */
#endif
