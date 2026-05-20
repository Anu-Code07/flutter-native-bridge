final class BridgeContract {
  const BridgeContract({
    required this.name,
    required this.channel,
    required this.version,
    required this.methods,
    required this.events,
  });

  final String name;
  final String channel;
  final int version;
  final List<BridgeOperation> methods;
  final List<BridgeOperation> events;
}

final class BridgeOperation {
  const BridgeOperation({
    required this.name,
    required this.returnType,
    required this.parameters,
    required this.isStream,
    this.timeoutMilliseconds,
  });

  final String name;
  final String returnType;
  final List<BridgeParameter> parameters;
  final bool isStream;
  final int? timeoutMilliseconds;
}

final class BridgeParameter {
  const BridgeParameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNullable,
  });

  final String name;
  final String type;
  final bool isRequired;
  final bool isNullable;
}
