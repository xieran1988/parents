
static gboolean
plugin_init (GstPlugin * plugin)
{
  /* debug category for fltering log messages
   *
   * exchange the string 'Template plugin' with your description
  GST_DEBUG_CATEGORY_INIT (gst_plugin_template_debug, "plugin",
      0, "Template plugin");
   */
  return gst_element_register (plugin, 
			"{p}", // modify here
			GST_RANK_NONE,
      gst_{a1}_get_type());
}

/* PACKAGE: this is usually set by autotools depending on some _INIT macro
 * in configure.ac and then written into and defined in config.h, but we can
 * just set it ourselves here in case someone doesn't use autotools to
 * compile this code. GST_PLUGIN_DEFINE needs PACKAGE to be defined.
 */
#ifndef PACKAGE
// modify here
#define PACKAGE "{p}package"
#endif

/* gstreamer looks for this structure to register plugins
 *
 * exchange the string 'Template plugin' with your plugin description
 */
GST_PLUGIN_DEFINE (
    GST_VERSION_MAJOR,
    GST_VERSION_MINOR,
		// and modify here
    "{p}plugin",
    "My {p} plugin",
    plugin_init,
    "0.10",
    "LGPL",
    "GStreamer",
    "http://gstreamer.net/"
)

