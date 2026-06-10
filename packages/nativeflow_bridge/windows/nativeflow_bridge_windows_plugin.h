#ifndef FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>

namespace nativeflow_bridge_windows {

using EncodableMethodCall = flutter::MethodCall<flutter::EncodableValue>;
using EncodableMethodResult =
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>;
using EncodableMethodHandler =
    std::function<void(const EncodableMethodCall&, EncodableMethodResult)>;
using EncodableEventSink = std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>;
using EncodableEventListenHandler = std::function<void(
    const flutter::EncodableValue* arguments, EncodableEventSink sink)>;
using EncodableEventCancelHandler =
    std::function<void(const flutter::EncodableValue* arguments)>;

class NativeFlowBridgeRuntime {
 public:
  explicit NativeFlowBridgeRuntime(flutter::BinaryMessenger* messenger);
  ~NativeFlowBridgeRuntime();

  void RegisterMethods(const std::string& channel_name,
                       EncodableMethodHandler handler);

  void RegisterEvents(const std::string& channel_name,
                      EncodableEventListenHandler on_listen,
                      EncodableEventCancelHandler on_cancel);

  void Dispose();

 private:
  flutter::BinaryMessenger* messenger_;
  std::unordered_map<
      std::string,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>>
      method_channels_;
  std::unordered_map<
      std::string,
      std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>>
      event_channels_;
};

class NativeFlowBridgeWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NativeFlowBridgeWindowsPlugin();
  ~NativeFlowBridgeWindowsPlugin() override;

  NativeFlowBridgeRuntime* runtime() { return runtime_.get(); }

 private:
  std::unique_ptr<NativeFlowBridgeRuntime> runtime_;
};

}  // namespace nativeflow_bridge_windows

#endif  // FLUTTER_PLUGIN_NATIVEFLOW_BRIDGE_WINDOWS_PLUGIN_H_
