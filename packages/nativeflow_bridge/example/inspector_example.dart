// ignore_for_file: avoid_print

import 'package:nativeflow_bridge/devtools.dart';

/// Demonstrates the in-process [BridgeInspector] without a Flutter binding.
///
/// In a real app you would mount `BridgeInspectorPanel` from
/// `package:nativeflow_bridge/devtools.dart` in a debug-only route.
void main() async {
  final inspector = BridgeInspector.instance
    ..clear()
    ..capturePayloads = true;

  inspector.events.listen((event) {
    print('[bridge] ${event.channel}/${event.operation} ${event.status.name} '
        '${event.duration?.inMicroseconds ?? '-'}µs');
  });

  // Synthetic event: pretend we just invoked a payment method.
  final start = inspector.nextId();
  inspector.record(
    BridgeTimelineEvent(
      id: start,
      bridge: 'PaymentBridge',
      channel: 'nativeflow/payments',
      operation: 'pay',
      kind: BridgeOperationKind.method,
      status: BridgeOperationStatus.started,
      startedAt: DateTime.now(),
      transport: 'methodChannel',
      requestPreview: <String, Object?>{
        'amountMinor': 1999,
        'currency': 'INR',
        'cardToken': 'secret',
      },
    ),
  );

  await Future<void>.delayed(const Duration(milliseconds: 7));

  inspector.record(
    BridgeTimelineEvent(
      id: start,
      bridge: 'PaymentBridge',
      channel: 'nativeflow/payments',
      operation: 'pay',
      kind: BridgeOperationKind.method,
      status: BridgeOperationStatus.success,
      startedAt: DateTime.now().subtract(const Duration(milliseconds: 7)),
      completedAt: DateTime.now(),
      transport: 'methodChannel',
      responseBytes: 64,
    ),
  );

  print('--- stats ---');
  for (final stat in inspector.stats) {
    print(stat.toJson());
  }

  print('--- export ---');
  print(inspector.exportJson());
}

