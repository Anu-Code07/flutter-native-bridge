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
