import Flutter
import UIKit

public final class NativeFlowBridgePlugin: NSObject, FlutterPlugin {
  private var runtime: NativeFlowBridgeRuntime?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeFlowBridgePlugin()
    instance.runtime = NativeFlowBridgeRuntime(messenger: registrar.messenger())
    registrar.addApplicationDelegate(instance)
  }
}
