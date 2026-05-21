import 'package:meta/meta.dart';

import 'bridge_transport.dart';

/// Stable metadata emitted by the generator and consumed by runtimes/devtools.
@immutable
final class BridgeDescriptor {
  const BridgeDescriptor({
    required this.name,
    required this.channel,
    required this.version,
    required this.methods,
    this.events = const <BridgeEventDescriptor>[],
  });

  final String name;
  final String channel;
  final int version;
  final List<BridgeMethodDescriptor> methods;
  final List<BridgeEventDescriptor> events;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'channel': channel,
    'version': version,
    'methods': methods.map((method) => method.toJson()).toList(),
    'events': events.map((event) => event.toJson()).toList(),
  };
}

@immutable
final class BridgeMethodDescriptor {
  const BridgeMethodDescriptor({
    required this.name,
    required this.returnType,
    required this.parameters,
    this.transport = BridgeTransport.methodChannel,
    this.timeoutMilliseconds,
  });

  final String name;
  final String returnType;
  final List<BridgeParameterDescriptor> parameters;
  final BridgeTransport transport;
  final int? timeoutMilliseconds;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'returnType': returnType,
    'transport': transport.name,
    'timeoutMilliseconds': timeoutMilliseconds,
    'parameters': parameters.map((parameter) => parameter.toJson()).toList(),
  };
}

@immutable
final class BridgeEventDescriptor {
  const BridgeEventDescriptor({
    required this.name,
    required this.payloadType,
    this.replay = 0,
    this.bufferSize = 64,
  });

  final String name;
  final String payloadType;
  final int replay;
  final int bufferSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'payloadType': payloadType,
    'replay': replay,
    'bufferSize': bufferSize,
  };
}

@immutable
final class BridgeParameterDescriptor {
  const BridgeParameterDescriptor({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNullable,
  });

  final String name;
  final String type;
  final bool isRequired;
  final bool isNullable;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'type': type,
    'isRequired': isRequired,
    'isNullable': isNullable,
  };
}
