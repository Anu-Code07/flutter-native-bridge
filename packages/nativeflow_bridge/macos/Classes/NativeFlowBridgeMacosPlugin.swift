import Cocoa
import FlutterMacOS

public final class NativeFlowBridgeMacosPlugin: NSObject, FlutterPlugin {
  private var runtime: NativeFlowBridgeRuntime?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeFlowBridgeMacosPlugin()
    instance.runtime = NativeFlowBridgeRuntime(messenger: registrar.messenger)
  }
}
