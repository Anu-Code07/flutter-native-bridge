import Flutter
import Foundation

public protocol NativeFlowMethodHandler {
  func handle(method: String, arguments: Any?) async throws -> Any?
}

public protocol NativeFlowEventSource {
  func onListen(arguments: Any?, sink: @escaping FlutterEventSink)
  func onCancel(arguments: Any?)
}

public final class NativeFlowBridgeRuntime {
  private let messenger: FlutterBinaryMessenger
  private var methodChannels: [String: FlutterMethodChannel] = [:]
  private var eventChannels: [String: FlutterEventChannel] = [:]

  public init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  public func registerMethods(
    channelName: String,
    handler: NativeFlowMethodHandler
  ) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      Task {
        do {
          result(try await handler.handle(method: call.method, arguments: call.arguments))
        } catch {
          result(FlutterError(
            code: String(describing: type(of: error)),
            message: error.localizedDescription,
            details: ["description": String(describing: error)]
          ))
        }
      }
    }
    methodChannels[channelName] = channel
  }

  public func registerEvents(
    channelName: String,
    source: NativeFlowEventSource
  ) {
    let streamHandler = NativeFlowStreamHandler(source: source)
    let channel = FlutterEventChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setStreamHandler(streamHandler)
    eventChannels[channelName] = channel
  }
}

private final class NativeFlowStreamHandler: NSObject, FlutterStreamHandler {
  private let source: NativeFlowEventSource

  init(source: NativeFlowEventSource) {
    self.source = source
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    source.onListen(arguments: arguments, sink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    source.onCancel(arguments: arguments)
    return nil
  }
}
