import FlutterMacOS
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

  /// When `false` (default in release) the runtime omits stack traces and
  /// native exception descriptions from cross-boundary error details.
  public var emitDebugErrorDetails: Bool = {
    #if DEBUG
    return true
    #else
    return false
    #endif
  }()

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
    let emitDebugErrorDetails = self.emitDebugErrorDetails
    channel.setMethodCallHandler { call, result in
      Task {
        do {
          result(try await handler.handle(method: call.method, arguments: call.arguments))
        } catch let bridgeError as NativeFlowBridgeError {
          result(bridgeError.asFlutterError(emitDebug: emitDebugErrorDetails))
        } catch {
          result(FlutterError(
            code: String(describing: type(of: error)),
            message: error.localizedDescription,
            details: emitDebugErrorDetails
              ? ["description": String(describing: error)]
              : nil
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

  public func dispose() {
    methodChannels.values.forEach { $0.setMethodCallHandler(nil) }
    eventChannels.values.forEach { $0.setStreamHandler(nil) }
    methodChannels.removeAll()
    eventChannels.removeAll()
  }
}

/// Typed error thrown by native handlers that maps cleanly to `@BridgeError`.
public struct NativeFlowBridgeError: Error {
  public let code: String
  public let message: String
  public let details: Any?

  public init(code: String, message: String, details: Any? = nil) {
    self.code = code
    self.message = message
    self.details = details
  }

  public func asFlutterError(emitDebug: Bool) -> FlutterError {
    FlutterError(code: code, message: message, details: emitDebug ? details : nil)
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
