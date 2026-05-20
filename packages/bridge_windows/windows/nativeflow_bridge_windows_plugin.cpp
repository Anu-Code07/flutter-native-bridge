#include "nativeflow_bridge_windows_plugin.h"

namespace nativeflow_bridge_windows {

NativeFlowBridgeWindowsPlugin::NativeFlowBridgeWindowsPlugin() = default;
NativeFlowBridgeWindowsPlugin::~NativeFlowBridgeWindowsPlugin() = default;

void NativeFlowBridgeWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "nativeflow/runtime",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeFlowBridgeWindowsPlugin>();
  plugin->channel_ = std::move(channel);
  registrar->AddPlugin(std::move(plugin));
}

}  // namespace nativeflow_bridge_windows
