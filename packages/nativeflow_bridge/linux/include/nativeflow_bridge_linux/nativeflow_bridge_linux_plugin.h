#ifndef FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_LINUX_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#define NATIVEFLOW_BRIDGE_LINUX_TYPE_PLUGIN \
  (nativeflow_bridge_linux_plugin_get_type())

G_DECLARE_FINAL_TYPE(NativeFlowBridgeLinuxPlugin,
                     nativeflow_bridge_linux_plugin,
                     NATIVEFLOW_BRIDGE_LINUX,
                     PLUGIN,
                     GObject)

void nativeflow_bridge_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

/**
 * Registers a method-call handler against `channel_name`. The handler must
 * outlive the plugin or be released via fl_method_channel_set_method_call_handler
 * with NULL.
 */
FlMethodChannel* nativeflow_bridge_linux_register_method_channel(
    FlPluginRegistrar* registrar,
    const gchar* channel_name,
    FlMethodChannelMethodCallHandler handler,
    gpointer user_data,
    GDestroyNotify destroy_notify);

/**
 * Registers an event channel for streaming bridge events.
 */
FlEventChannel* nativeflow_bridge_linux_register_event_channel(
    FlPluginRegistrar* registrar,
    const gchar* channel_name,
    FlEventChannelStreamHandlerCb on_listen,
    FlEventChannelStreamHandlerCb on_cancel,
    gpointer user_data,
    GDestroyNotify destroy_notify);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_LINUX_PLUGIN_H_
