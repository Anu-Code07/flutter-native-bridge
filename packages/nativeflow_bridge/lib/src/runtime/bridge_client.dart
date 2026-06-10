import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/src/devtools/bridge_redactor.dart';
import 'package:nativeflow_bridge/src/devtools/bridge_timeline.dart';

import 'bridge_error_mapper.dart';
import 'bridge_event_stream.dart';

/// Runtime facade used by generated Dart bridge proxies.
///
/// Generated `_$YourBridgeClient` types instantiate a [BridgeClient] with the
/// emitted descriptor and forward each generated method/event call. The client
/// is responsible for:
///
/// - codec encoding / decoding
/// - serializer dispatch
/// - method / message / event transports
/// - configurable per-call timeouts
/// - typed error mapping (`@BridgeError`)
/// - DevTools telemetry via [BridgeInspector]
final class BridgeClient {
  BridgeClient({
    required BridgeDescriptor descriptor,
    BridgeCodec codec = const IdentityBridgeCodec(),
    BridgeSerializerRegistry? serializers,
    BinaryMessenger? binaryMessenger,
    BridgeInspector? inspector,
    BridgeErrorMapper? errorMapper,
    BridgePayloadRedactor? redactor,
  }) : this._(
         descriptor: descriptor,
         codec: codec,
         serializers: serializers ?? BridgeSerializerRegistry(),
         binaryMessenger: binaryMessenger,
         inspector: inspector ?? BridgeInspector.instance,
         errorMapper:
             errorMapper ?? BridgeErrorMapper.fromDescriptor(descriptor),
         redactor: redactor ?? BridgePayloadRedactor(),
       );

  BridgeClient._({
    required this.descriptor,
    required BridgeCodec codec,
    required BridgeSerializerRegistry serializers,
    required BridgeInspector inspector,
    required BridgeErrorMapper errorMapper,
    required BridgePayloadRedactor redactor,
    BinaryMessenger? binaryMessenger,
  }) : _codec = codec,
       _serializers = serializers,
       _inspector = inspector,
       _errorMapper = errorMapper,
       _redactor = redactor,
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
         serializers: serializers,
         binaryMessenger: binaryMessenger,
         inspector: inspector,
         errorMapper: errorMapper,
       );

  final BridgeDescriptor descriptor;
  final BridgeCodec _codec;
  final BridgeSerializerRegistry _serializers;
  final BridgeInspector _inspector;
  final BridgeErrorMapper _errorMapper;
  final BridgePayloadRedactor _redactor;
  final MethodChannel _methodChannel;
  final BasicMessageChannel<Object?> _messageChannel;
  final BridgeEventStreamRegistry _eventStreams;

  /// Underlying error mapper. Application code can register additional
  /// `@BridgeError`-coded factories on this instance.
  BridgeErrorMapper get errorMapper => _errorMapper;

  /// Underlying DevTools inspector instance.
  BridgeInspector get inspector => _inspector;

  Future<T> invoke<T>(
    String method, {
    Object? arguments,
    Duration? timeout,
  }) async {
    final encodedArguments = _codec.encode(
      _serializers.serializeValue(arguments),
    );
    final telemetryId = _recordStarted(
      operation: method,
      kind: BridgeOperationKind.method,
      transport: 'methodChannel',
      requestPayload: encodedArguments,
    );
    final stopwatch = Stopwatch()..start();
    final operation = _methodChannel.invokeMethod<Object?>(
      method,
      encodedArguments,
    );

    try {
      final value =
          timeout == null
              ? await operation
              : await operation.timeout(
                timeout,
                onTimeout: () {
                  _recordTerminal(
                    id: telemetryId,
                    operation: method,
                    kind: BridgeOperationKind.method,
                    status: BridgeOperationStatus.timeout,
                    startedAt: _startedAt(stopwatch),
                    errorCode: 'timeout',
                    errorMessage:
                        'Bridge call "$method" timed out after $timeout.',
                    transport: 'methodChannel',
                  );
                  throw BridgeTimeoutException(
                    'Bridge call "$method" timed out after $timeout.',
                  );
                },
              );
      final decoded = _serializers.deserializeValue<T>(
        _codec.decode<Object?>(value),
      );
      _recordTerminal(
        id: telemetryId,
        operation: method,
        kind: BridgeOperationKind.method,
        status: BridgeOperationStatus.success,
        startedAt: _startedAt(stopwatch),
        responsePayload: value,
        transport: 'methodChannel',
      );
      return decoded;
    } on PlatformException catch (error, stackTrace) {
      final mapped = _errorMapper.map(error, stackTrace);
      _recordTerminal(
        id: telemetryId,
        operation: method,
        kind: BridgeOperationKind.method,
        status: BridgeOperationStatus.error,
        startedAt: _startedAt(stopwatch),
        errorCode: mapped.code,
        errorMessage: mapped.message,
        transport: 'methodChannel',
      );
      throw mapped;
    }
  }

  Future<T> send<T>(
    String endpoint, {
    Object? message,
    Duration? timeout,
  }) async {
    final encodedMessage = _codec.encode(_serializers.serializeValue(message));
    final payload = <String, Object?>{
      'endpoint': endpoint,
      'message': encodedMessage,
    };
    final telemetryId = _recordStarted(
      operation: endpoint,
      kind: BridgeOperationKind.message,
      transport: 'basicMessageChannel',
      requestPayload: encodedMessage,
    );
    final stopwatch = Stopwatch()..start();
    final operation = _messageChannel.send(payload);

    try {
      final value =
          timeout == null
              ? await operation
              : await operation.timeout(
                timeout,
                onTimeout: () {
                  _recordTerminal(
                    id: telemetryId,
                    operation: endpoint,
                    kind: BridgeOperationKind.message,
                    status: BridgeOperationStatus.timeout,
                    startedAt: _startedAt(stopwatch),
                    errorCode: 'timeout',
                    errorMessage:
                        'Bridge message "$endpoint" timed out after $timeout.',
                    transport: 'basicMessageChannel',
                  );
                  throw BridgeTimeoutException(
                    'Bridge message "$endpoint" timed out after $timeout.',
                  );
                },
              );
      final decoded = _serializers.deserializeValue<T>(
        _codec.decode<Object?>(value),
      );
      _recordTerminal(
        id: telemetryId,
        operation: endpoint,
        kind: BridgeOperationKind.message,
        status: BridgeOperationStatus.success,
        startedAt: _startedAt(stopwatch),
        responsePayload: value,
        transport: 'basicMessageChannel',
      );
      return decoded;
    } on PlatformException catch (error, stackTrace) {
      final mapped = _errorMapper.map(error, stackTrace);
      _recordTerminal(
        id: telemetryId,
        operation: endpoint,
        kind: BridgeOperationKind.message,
        status: BridgeOperationStatus.error,
        startedAt: _startedAt(stopwatch),
        errorCode: mapped.code,
        errorMessage: mapped.message,
        transport: 'basicMessageChannel',
      );
      throw mapped;
    }
  }

  Stream<T> events<T>(
    String eventName, {
    Duration reconnectDelay = const Duration(milliseconds: 250),
  }) {
    return _eventStreams.stream<T>(eventName, reconnectDelay: reconnectDelay);
  }

  int _recordStarted({
    required String operation,
    required BridgeOperationKind kind,
    required String transport,
    Object? requestPayload,
  }) {
    final id = _inspector.nextId();
    _inspector.record(
      BridgeTimelineEvent(
        id: id,
        bridge: descriptor.name,
        channel: descriptor.channel,
        operation: operation,
        kind: kind,
        status: BridgeOperationStatus.started,
        startedAt: DateTime.now(),
        requestBytes: estimatePayloadBytes(requestPayload),
        transport: transport,
        requestPreview:
            _inspector.capturePayloads
                ? _redactor.redact(requestPayload)
                : null,
      ),
    );
    return id;
  }

  void _recordTerminal({
    required int id,
    required String operation,
    required BridgeOperationKind kind,
    required BridgeOperationStatus status,
    required DateTime startedAt,
    required String transport,
    Object? responsePayload,
    String? errorCode,
    String? errorMessage,
  }) {
    _inspector.record(
      BridgeTimelineEvent(
        id: id,
        bridge: descriptor.name,
        channel: descriptor.channel,
        operation: operation,
        kind: kind,
        status: status,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        responseBytes: estimatePayloadBytes(responsePayload),
        errorCode: errorCode,
        errorMessage: errorMessage,
        transport: transport,
        responsePreview:
            _inspector.capturePayloads
                ? _redactor.redact(responsePayload)
                : null,
      ),
    );
  }

  DateTime _startedAt(Stopwatch stopwatch) =>
      DateTime.now().subtract(stopwatch.elapsed);
}
