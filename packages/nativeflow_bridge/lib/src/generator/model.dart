final class BridgeContract {
  const BridgeContract({
    required this.name,
    required this.channel,
    required this.version,
    required this.methods,
    required this.events,
    required this.errors,
    required this.codec,
    required this.platforms,
  });

  final String name;
  final String channel;
  final int version;
  final List<BridgeOperation> methods;
  final List<BridgeOperation> events;
  final List<BridgeErrorBinding> errors;

  /// One of: `identity`, `json`, `binary`, `protobuf`, `custom`.
  final String codec;

  /// Native platform target names (lower-case): android, ios, macos, ...
  final List<String> platforms;
}

final class BridgeOperation {
  const BridgeOperation({
    required this.name,
    required this.returnType,
    required this.parameters,
    required this.isStream,
    this.timeoutMilliseconds,
    this.transport = 'methodChannel',
    this.replay = 0,
    this.bufferSize = 64,
  });

  final String name;
  final String returnType;
  final List<BridgeParameter> parameters;
  final bool isStream;
  final int? timeoutMilliseconds;

  /// `methodChannel`, `eventChannel`, `basicMessageChannel`, or `ffi`.
  final String transport;
  final int replay;
  final int bufferSize;
}

final class BridgeParameter {
  const BridgeParameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    this.isNamed = false,
    this.isOptionalPositional = false,
    this.defaultValueCode,
  });

  final String name;
  final String type;
  final bool isRequired;
  final bool isNullable;
  final bool isNamed;
  final bool isOptionalPositional;
  final String? defaultValueCode;
}

/// A `@BridgeError`-annotated exception class discovered by the generator.
final class BridgeErrorBinding {
  const BridgeErrorBinding({required this.dartType, required this.code});

  final String dartType;
  final String code;
}

/// FFI bridge contract for `@FFIBridge` types.
final class FfiBridgeContract {
  const FfiBridgeContract({
    required this.name,
    required this.library,
    required this.symbolPrefix,
    required this.threading,
    required this.methods,
  });

  final String name;
  final String? library;
  final String? symbolPrefix;

  /// `main`, `worker`, or `isolate`.
  final String threading;
  final List<FfiBridgeMethod> methods;
}

final class FfiBridgeMethod {
  const FfiBridgeMethod({
    required this.name,
    required this.returnType,
    required this.symbolName,
    required this.parameters,
  });

  final String name;
  final String returnType;
  final String symbolName;
  final List<BridgeParameter> parameters;
}
