/// Transport families supported by NativeFlow Bridge.
enum BridgeTransport {
  /// Standard request/response over a Flutter [MethodChannel].
  methodChannel,

  /// Long-lived broadcast over a Flutter [EventChannel].
  eventChannel,

  /// Fire-and-receive messaging over a [BasicMessageChannel].
  basicMessageChannel,

  /// In-process Dart FFI bindings into a native dynamic library.
  ffi,
}

/// Codec families supported by NativeFlow Bridge generated transports.
enum BridgeCodecKind {
  /// Pass-through of [StandardMessageCodec]-compatible values.
  identity,

  /// `dart:convert` JSON encoded payloads.
  json,

  /// Binary payloads encoded as `Uint8List`.
  binary,

  /// Protobuf encoded payloads (consumer-provided codec).
  protobuf,

  /// Application-supplied codec implementation.
  custom,
}

/// Native platforms a generated contract should target.
enum BridgePlatformTarget { android, ios, macos, windows, linux, ffi }

/// Execution policy for asynchronous native work.
enum BridgeExecutionPolicy { mainThread, backgroundThread, isolate }
