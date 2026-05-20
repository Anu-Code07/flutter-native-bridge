import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nativeflow_bridge_core/bridge_core.dart';

import 'bridge_event_stream.dart';

/// Runtime facade used by generated Dart bridge proxies.
final class BridgeClient {
  BridgeClient({
    required BridgeDescriptor descriptor,
    BridgeCodec codec = const IdentityBridgeCodec(),
    BridgeSerializerRegistry? serializers,
    BinaryMessenger? binaryMessenger,
  }) : this._(
          descriptor: descriptor,
          codec: codec,
          serializers: serializers ?? BridgeSerializerRegistry(),
          binaryMessenger: binaryMessenger,
        );

  BridgeClient._({
    required this.descriptor,
    required BridgeCodec codec,
    required BridgeSerializerRegistry serializers,
    BinaryMessenger? binaryMessenger,
  })  : _codec = codec,
        _serializers = serializers,
        _methodChannel = MethodChannel(
          descriptor.channel,
          const StandardMethodCodec(),
          binaryMessenger,
        ),
        _messageChannel = BasicMessageChannel<Object?>(
          '${descriptor.channel}/messages',
          const StandardMessageCodec(),
          binaryMessenger: binaryMessenger,
        ),
        _eventStreams = BridgeEventStreamRegistry(
          descriptor: descriptor,
          codec: codec,
          serializers: _serializers,
          binaryMessenger: binaryMessenger,
        );

  final BridgeDescriptor descriptor;
  final BridgeCodec _codec;
  final BridgeSerializerRegistry _serializers;
  final MethodChannel _methodChannel;
  final BasicMessageChannel<Object?> _messageChannel;
  final BridgeEventStreamRegistry _eventStreams;

  Future<T> invoke<T>(
    String method, {
    Object? arguments,
    Duration? timeout,
  }) async {
    final encodedArguments = _codec.encode(
      _serializers.serializeValue(arguments),
    );
    final operation = _methodChannel.invokeMethod<Object?>(
      method,
      encodedArguments,
    );

    try {
      final value = timeout == null
          ? await operation
          : await operation.timeout(
              timeout,
              onTimeout: () => throw BridgeTimeoutException(
                'Bridge call "$method" timed out after $timeout.',
              ),
            );
      return _serializers.deserializeValue<T>(_codec.decode<Object?>(value));
    } on PlatformException catch (error, stackTrace) {
      throw _mapPlatformException(error, stackTrace);
    }
  }

  Future<T> send<T>(
    String endpoint, {
    Object? message,
    Duration? timeout,
  }) async {
    final payload = <String, Object?>{
      'endpoint': endpoint,
      'message': _codec.encode(_serializers.serializeValue(message)),
    };
    final operation = _messageChannel.send(payload);

    try {
      final value = timeout == null
          ? await operation
          : await operation.timeout(
              timeout,
              onTimeout: () => throw BridgeTimeoutException(
                'Bridge message "$endpoint" timed out after $timeout.',
              ),
            );
      return _serializers.deserializeValue<T>(_codec.decode<Object?>(value));
    } on PlatformException catch (error, stackTrace) {
      throw _mapPlatformException(error, stackTrace);
    }
  }

  Stream<T> events<T>(
    String eventName, {
    Duration reconnectDelay = const Duration(milliseconds: 250),
  }) {
    return _eventStreams.stream<T>(
      eventName,
      reconnectDelay: reconnectDelay,
    );
  }

  BridgePlatformException _mapPlatformException(
    PlatformException error,
    StackTrace stackTrace,
  ) {
    return BridgePlatformException(
      error.message ?? 'Native bridge call failed.',
      code: error.code,
      details: error.details,
      platform: defaultTargetPlatform.name,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
