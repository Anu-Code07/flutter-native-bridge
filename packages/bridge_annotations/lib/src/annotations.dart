/// Marks an abstract Dart class as a generated platform bridge.
class Bridge {
  /// Creates a platform bridge contract.
  const Bridge({
    this.channel,
    this.version = 1,
    this.codec = BridgeCodec.json,
    this.platforms = const <BridgePlatform>[
      BridgePlatform.android,
      BridgePlatform.ios,
      BridgePlatform.macos,
      BridgePlatform.windows,
      BridgePlatform.linux,
    ],
  });

  /// Stable channel namespace. Defaults to the annotated class name.
  final String? channel;

  /// Contract version used for native/Dart compatibility checks.
  final int version;

  /// Serialization strategy for generated transports.
  final BridgeCodec codec;

  /// Platforms that should receive generated native contracts.
  final List<BridgePlatform> platforms;
}

/// Marks an abstract Dart class as a generated FFI bridge.
class FFIBridge {
  /// Creates an FFI bridge contract.
  const FFIBridge({
    this.library,
    this.symbolPrefix,
    this.threading = FFIThreading.worker,
  });

  /// Dynamic library name or lookup hint.
  final String? library;

  /// Optional prefix applied to generated native symbol names.
  final String? symbolPrefix;

  /// Execution model for generated native calls.
  final FFIThreading threading;
}

/// Overrides a generated method or event name.
class BridgeMethod {
  /// Creates a method-level bridge configuration.
  const BridgeMethod({
    this.name,
    this.timeout,
    this.transport = BridgeTransport.methodChannel,
  });

  final String? name;
  final Duration? timeout;
  final BridgeTransport transport;
}

/// Marks a bridge method as an event stream endpoint.
class BridgeEvent {
  /// Creates an event stream configuration.
  const BridgeEvent({
    this.name,
    this.replay = 0,
    this.bufferSize = 64,
  });

  final String? name;
  final int replay;
  final int bufferSize;
}

/// Registers a Dart exception class as a typed native error.
class BridgeError {
  /// Creates a typed error mapping.
  const BridgeError(this.code);

  final String code;
}

/// Registers a custom serializer for a Dart type.
class BridgeSerializable {
  /// Creates serializer metadata for generated codecs.
  const BridgeSerializable({
    this.discriminator,
    this.serializer,
  });

  final String? discriminator;
  final Type? serializer;
}

enum BridgeCodec {
  json,
  binary,
  protobuf,
  custom,
}

enum BridgePlatform {
  android,
  ios,
  macos,
  windows,
  linux,
}

enum BridgeTransport {
  methodChannel,
  eventChannel,
  basicMessageChannel,
  ffi,
}

enum FFIThreading {
  main,
  worker,
  isolate,
}
