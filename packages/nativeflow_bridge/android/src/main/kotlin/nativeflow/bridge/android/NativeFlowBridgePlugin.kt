package nativeflow.bridge.android

import io.flutter.embedding.engine.plugins.FlutterPlugin

class NativeFlowBridgePlugin : FlutterPlugin {
  private var runtime: NativeFlowBridgeRuntime? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    runtime = NativeFlowBridgeRuntime(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    runtime?.dispose()
    runtime = null
  }
}
