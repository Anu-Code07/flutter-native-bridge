#ifndef FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <memory>
#include <string>

namespace nativeflow_bridge_windows {

class NativeFlowBridgeWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NativeFlowBridgeWindowsPlugin();
  ~NativeFlowBridgeWindowsPlugin() override;

 private:
  using MethodHandler = std::function<void(
      const flutter::MethodCall<flutter::EncodableValue>&,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace nativeflow_bridge_windows

#endif  // FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_
