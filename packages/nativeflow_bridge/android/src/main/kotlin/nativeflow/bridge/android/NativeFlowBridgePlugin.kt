package nativeflow.bridge.android

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter plugin entrypoint. Owns one [NativeFlowBridgeRuntime] per
 * Flutter engine; applications register their generated method/event
 * handlers against [runtime] from native code.
 */
class NativeFlowBridgePlugin : FlutterPlugin {
  private var _runtime: NativeFlowBridgeRuntime? = null

  /** Active runtime, or `null` outside the attached lifecycle. */
  val runtime: NativeFlowBridgeRuntime?
    get() = _runtime

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    _runtime = NativeFlowBridgeRuntime(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    _runtime?.dispose()
    _runtime = null
  }
}
