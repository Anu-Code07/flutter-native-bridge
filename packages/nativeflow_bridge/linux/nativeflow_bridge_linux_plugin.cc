#include "include/nativeflow_bridge_linux/nativeflow_bridge_linux_plugin.h"

struct _NativeFlowBridgeLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(
    NativeFlowBridgeLinuxPlugin,
    nativeflow_bridge_linux_plugin,
    g_object_get_type())

static void nativeflow_bridge_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(nativeflow_bridge_linux_plugin_parent_class)->dispose(object);
}

static void nativeflow_bridge_linux_plugin_class_init(
    NativeFlowBridgeLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = nativeflow_bridge_linux_plugin_dispose;
}

static void nativeflow_bridge_linux_plugin_init(
    NativeFlowBridgeLinuxPlugin* self) {}

void nativeflow_bridge_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  g_autoptr(NativeFlowBridgeLinuxPlugin) plugin =
      NATIVEFLOW_BRIDGE_LINUX_PLUGIN(
          g_object_new(nativeflow_bridge_linux_plugin_get_type(), nullptr));
  g_object_ref_sink(plugin);
}

FlMethodChannel* nativeflow_bridge_linux_register_method_channel(
    FlPluginRegistrar* registrar,
    const gchar* channel_name,
    FlMethodChannelMethodCallHandler handler,
    gpointer user_data,
    GDestroyNotify destroy_notify) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      channel_name,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, handler, user_data,
                                            destroy_notify);
  return channel;
}

FlEventChannel* nativeflow_bridge_linux_register_event_channel(
    FlPluginRegistrar* registrar,
    const gchar* channel_name,
    FlEventChannelStreamHandlerCb on_listen,
    FlEventChannelStreamHandlerCb on_cancel,
    gpointer user_data,
    GDestroyNotify destroy_notify) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      channel_name,
      FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, on_listen, on_cancel, user_data,
                                       destroy_notify);
  return channel;
}
