#include "nativeflow_bridge_windows_plugin.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <utility>

namespace nativeflow_bridge_windows {

NativeFlowBridgeRuntime::NativeFlowBridgeRuntime(
    flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {}

NativeFlowBridgeRuntime::~NativeFlowBridgeRuntime() { Dispose(); }

void NativeFlowBridgeRuntime::RegisterMethods(
    const std::string& channel_name, EncodableMethodHandler handler) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger_, channel_name,
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [handler = std::move(handler)](const EncodableMethodCall& call,
                                     EncodableMethodResult result) {
        handler(call, std::move(result));
      });
  method_channels_[channel_name] = std::move(channel);
}

void NativeFlowBridgeRuntime::RegisterEvents(
    const std::string& channel_name,
    EncodableEventListenHandler on_listen,
    EncodableEventCancelHandler on_cancel) {
  auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger_, channel_name,
          &flutter::StandardMethodCodec::GetInstance());
  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [on_listen = std::move(on_listen)](
              const flutter::EncodableValue* arguments,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                  sink)
              -> std::unique_ptr<flutter::StreamHandlerError<
                  flutter::EncodableValue>> {
            on_listen(arguments, std::move(sink));
            return nullptr;
          },
          [on_cancel = std::move(on_cancel)](
              const flutter::EncodableValue* arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<
                  flutter::EncodableValue>> {
            on_cancel(arguments);
            return nullptr;
          });
  channel->SetStreamHandler(std::move(handler));
  event_channels_[channel_name] = std::move(channel);
}

void NativeFlowBridgeRuntime::Dispose() {
  method_channels_.clear();
  event_channels_.clear();
}

NativeFlowBridgeWindowsPlugin::NativeFlowBridgeWindowsPlugin() = default;
NativeFlowBridgeWindowsPlugin::~NativeFlowBridgeWindowsPlugin() = default;

void NativeFlowBridgeWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<NativeFlowBridgeWindowsPlugin>();
  plugin->runtime_ =
      std::make_unique<NativeFlowBridgeRuntime>(registrar->messenger());
  registrar->AddPlugin(std::move(plugin));
}

}  // namespace nativeflow_bridge_windows
