import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/src/devtools/bridge_timeline.dart';

import 'bridge_error_mapper.dart';

/// Multiplexes generated event streams over stable EventChannel names.
final class BridgeEventStreamRegistry {
  BridgeEventStreamRegistry({
    required BridgeDescriptor descriptor,
    required BridgeCodec codec,
    required BridgeSerializerRegistry serializers,
    BinaryMessenger? binaryMessenger,
    BridgeInspector? inspector,
    BridgeErrorMapper? errorMapper,
  }) : _descriptor = descriptor,
       _codec = codec,
       _serializers = serializers,
       _binaryMessenger = binaryMessenger,
       _inspector = inspector,
       _errorMapper =
           errorMapper ?? BridgeErrorMapper.fromDescriptor(descriptor);

  final BridgeDescriptor _descriptor;
  final BridgeCodec _codec;
  final BridgeSerializerRegistry _serializers;
  final BinaryMessenger? _binaryMessenger;
  final BridgeInspector? _inspector;
  final BridgeErrorMapper _errorMapper;
  final Map<String, _SharedEventStream> _sharedStreams =
      <String, _SharedEventStream>{};

  Stream<T> stream<T>(
    String eventName, {
    Duration reconnectDelay = const Duration(milliseconds: 250),
  }) {
    final descriptor =
        _descriptor.events.where((event) {
          return event.name == eventName;
        }).firstOrNull;

    if (descriptor == null) {
      throw BridgeRegistrationException(
        'No event "$eventName" registered for ${_descriptor.name}.',
      );
    }

    final shared = _sharedStreams.putIfAbsent(eventName, () {
      return _SharedEventStream(
        channelName: '${_descriptor.channel}/events/$eventName',
        bridgeName: _descriptor.name,
        bridgeChannel: _descriptor.channel,
        eventDescriptor: descriptor,
        binaryMessenger: _binaryMessenger,
        reconnectDelay: reconnectDelay,
        inspector: _inspector,
      );
    });

    return shared.stream
        .map<T>((event) {
          return _serializers.deserializeValue<T>(
            _codec.decode<Object?>(event),
          );
        })
        .handleError((Object error, StackTrace stackTrace) {
          if (error is PlatformException) {
            throw _errorMapper.map(error, stackTrace);
          }
          Error.throwWithStackTrace(error, stackTrace);
        });
  }
}

/// Per-event-name broadcast pipeline with replay + auto-reconnect.
class _SharedEventStream {
  _SharedEventStream({
    required this.channelName,
    required this.bridgeName,
    required this.bridgeChannel,
    required BridgeEventDescriptor eventDescriptor,
    required this.reconnectDelay,
    BinaryMessenger? binaryMessenger,
    BridgeInspector? inspector,
  }) : _channel = EventChannel(
         channelName,
         const StandardMethodCodec(),
         binaryMessenger,
       ),
       _eventDescriptor = eventDescriptor,
       _inspector = inspector;

  final String channelName;
  final String bridgeName;
  final String bridgeChannel;
  final EventChannel _channel;
  final BridgeEventDescriptor _eventDescriptor;
  final Duration reconnectDelay;
  final BridgeInspector? _inspector;

  StreamController<Object?>? _controller;
  StreamSubscription<Object?>? _subscription;
  final Queue<Object?> _replay = Queue<Object?>();
  bool _disposed = false;

  Stream<Object?> get stream {
    final existing = _controller;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }
    final controller = StreamController<Object?>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    _controller = controller;
    return controller.stream;
  }

  void _connect() {
    if (_disposed) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    for (final event in _replay) {
      controller.add(event);
    }
    _subscription = _channel.receiveBroadcastStream().listen(
      (Object? event) {
        if (_eventDescriptor.replay > 0) {
          _replay.add(event);
          while (_replay.length > _eventDescriptor.replay) {
            _replay.removeFirst();
          }
        }
        final inspector = _inspector;
        if (inspector != null) {
          inspector.record(
            BridgeTimelineEvent(
              id: inspector.nextId(),
              bridge: bridgeName,
              channel: channelName,
              operation: _eventDescriptor.name,
              kind: BridgeOperationKind.event,
              status: BridgeOperationStatus.success,
              startedAt: DateTime.now(),
              completedAt: DateTime.now(),
              responseBytes: estimatePayloadBytes(event),
              transport: 'eventChannel',
            ),
          );
        }
        controller.add(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        final inspector = _inspector;
        if (inspector != null) {
          inspector.record(
            BridgeTimelineEvent(
              id: inspector.nextId(),
              bridge: bridgeName,
              channel: channelName,
              operation: _eventDescriptor.name,
              kind: BridgeOperationKind.event,
              status: BridgeOperationStatus.error,
              startedAt: DateTime.now(),
              completedAt: DateTime.now(),
              errorCode:
                  error is PlatformException ? error.code : 'event_error',
              errorMessage:
                  error is PlatformException ? error.message : error.toString(),
              transport: 'eventChannel',
            ),
          );
        }
        controller.addError(error, stackTrace);
        _scheduleReconnect();
      },
      onDone: _scheduleReconnect,
      cancelOnError: false,
    );
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _scheduleReconnect() {
    if (_disposed) {
      return;
    }
    final controller = _controller;
    if (controller == null || controller.isClosed || !controller.hasListener) {
      return;
    }
    _subscription?.cancel();
    _subscription = null;
    Future<void>.delayed(reconnectDelay, () {
      if (_disposed) {
        return;
      }
      final stillListening = _controller?.hasListener ?? false;
      if (stillListening) {
        _connect();
      }
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
