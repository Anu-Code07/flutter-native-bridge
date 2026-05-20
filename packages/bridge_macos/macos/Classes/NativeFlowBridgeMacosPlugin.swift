import Cocoa
import FlutterMacOS

public final class NativeFlowBridgeMacosPlugin: NSObject, FlutterPlugin {
  private var runtime: NativeFlowBridgeRuntime?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeFlowBridgeMacosPlugin()
    instance.runtime = NativeFlowBridgeRuntime(messenger: registrar.messenger)
  }
}

public final class NativeFlowBridgeRuntime {
  private let messenger: FlutterBinaryMessenger

  public init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  public func register(
    channelName: String,
    handler: @escaping (FlutterMethodCall, @escaping FlutterResult) -> Void
  ) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handler)
  }
}
