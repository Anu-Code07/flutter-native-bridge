import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nativeflow_bridge/devtools.dart';

BridgeTimelineEvent _started(BridgeInspector inspector, {String op = 'pay'}) {
  return BridgeTimelineEvent(
    id: inspector.nextId(),
    bridge: 'PaymentBridge',
    channel: 'nativeflow/payments',
    operation: op,
    kind: BridgeOperationKind.method,
    status: BridgeOperationStatus.started,
    startedAt: DateTime(2026),
    transport: 'methodChannel',
  );
}

BridgeTimelineEvent _completed(
  BridgeTimelineEvent started, {
  BridgeOperationStatus status = BridgeOperationStatus.success,
  int micros = 1000,
  String? errorCode,
}) {
  return started.copyWith(
    status: status,
    completedAt: started.startedAt.add(Duration(microseconds: micros)),
    errorCode: errorCode,
  );
}

void main() {
  group('BridgeInspector', () {
    late BridgeInspector inspector;

    setUp(() {
      inspector = BridgeInspector.instance
        ..clear()
        ..isEnabled = true
        ..capturePayloads = false
        ..vmServiceBroadcast = false;
    });

    test('records started/terminal events and broadcasts them', () async {
      final received = <BridgeTimelineEvent>[];
      final subscription = inspector.events.listen(received.add);
      final started = _started(inspector);
      inspector.record(started);
      inspector.record(_completed(started));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(received, hasLength(2));
      expect(inspector.timeline.last.status, BridgeOperationStatus.success);
    });

    test('aggregates latency stats per operation', () {
      for (var index = 0; index < 3; index++) {
        final started = _started(inspector, op: 'pay');
        inspector.record(started);
        inspector.record(
          _completed(started, micros: 1000 * (index + 1)),
        );
      }
      final failedStart = _started(inspector, op: 'pay');
      inspector.record(failedStart);
      inspector.record(
        _completed(
          failedStart,
          status: BridgeOperationStatus.error,
          errorCode: 'payment_cancelled',
        ),
      );

      final stats = inspector.stats.single;
      expect(stats.totalCalls, 4);
      expect(stats.errorCount, 1);
      expect(stats.minMicros, 1000);
      expect(stats.maxMicros, 3000);
    });

    test('export contains events and stats', () {
      final started = _started(inspector);
      inspector.record(started);
      inspector.record(_completed(started));
      final decoded = jsonDecode(inspector.exportJson()) as Map<String, Object?>;
      expect(decoded['version'], 1);
      expect((decoded['events']! as List<Object?>), hasLength(1));
      expect((decoded['stats']! as List<Object?>), hasLength(1));
    });

    test('isEnabled = false drops events', () {
      inspector.isEnabled = false;
      inspector.record(_started(inspector));
      expect(inspector.timeline, isEmpty);
    });

    test('ring buffer is bounded by capacity', () {
      final localInspector = BridgeInspector.instance
        ..clear()
        ..isEnabled = true;
      for (var index = 0; index < localInspector.capacity + 10; index++) {
        localInspector.record(_started(localInspector));
      }
      expect(localInspector.timeline.length, localInspector.capacity);
    });

    test('estimatePayloadBytes handles common shapes', () {
      expect(estimatePayloadBytes(null), 0);
      expect(estimatePayloadBytes('hello'), 5);
      expect(estimatePayloadBytes(<int>[1, 2, 3]), 3);
      expect(estimatePayloadBytes(<String, Object?>{'a': 1}), greaterThan(0));
    });
  });
}
