import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nativeflow_bridge_core/bridge_core.dart';

/// Multiplexes generated event streams over stable EventChannel names.
final class BridgeEventStreamRegistry {
  BridgeEventStreamRegistry({
    required BridgeDescriptor descriptor,
    required BridgeCodec codec,
    required BridgeSerializerRegistry serializers,
    BinaryMessenger? binaryMessenger,
  })  : _descriptor = descriptor,
        _codec = codec,
        _serializers = serializers,
        _binaryMessenger = binaryMessenger;

  final BridgeDescriptor _descriptor;
  final BridgeCodec _codec;
  final BridgeSerializerRegistry _serializers;
  final BinaryMessenger? _binaryMessenger;
  final Map<String, Stream<Object?>> _sharedStreams =
      <String, Stream<Object?>>{};

  Stream<T> stream<T>(
    String eventName, {
    Duration reconnectDelay = const Duration(milliseconds: 250),
  }) {
    final descriptor = _descriptor.events.where((event) {
      return event.name == eventName;
    }).firstOrNull;

    if (descriptor == null) {
      throw BridgeRegistrationException(
        'No event "$eventName" registered for ${_descriptor.name}.',
      );
    }

    final source = _sharedStreams.putIfAbsent(eventName, () {
      final channel = EventChannel(
        '${_descriptor.channel}/events/$eventName',
        const StandardMethodCodec(),
        _binaryMessenger,
      );
      return channel.receiveBroadcastStream().asBroadcastStream();
    });

    return source.map<T>((event) {
      return _serializers.deserializeValue<T>(_codec.decode<Object?>(event));
    }).handleError((Object error, StackTrace stackTrace) {
      if (error is PlatformException) {
        throw BridgePlatformException(
          error.message ?? 'Native event stream failed.',
          code: error.code,
          details: error.details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
