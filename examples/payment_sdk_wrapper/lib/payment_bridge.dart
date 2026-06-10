import 'dart:async';

import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'payment_bridge.g.dart';

@Bridge(channel: 'nativeflow/payments', version: 1)
abstract class PaymentBridge {
  Future<PaymentResult> pay(PaymentRequest request);

  @BridgeEvent(name: 'events', replay: 1, bufferSize: 128)
  Stream<PaymentEvent> events();

  Future<void> cancelPayment();
}

final class PaymentRequest {
  const PaymentRequest({
    required this.amountMinor,
    required this.currency,
    required this.orderId,
    this.metadata = const <String, Object?>{},
  });

  final int amountMinor;
  final String currency;
  final String orderId;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'amountMinor': amountMinor,
    'currency': currency,
    'orderId': orderId,
    'metadata': metadata,
  };
}

final class PaymentResult {
  const PaymentResult({required this.paymentId, required this.status});

  final String paymentId;
  final PaymentStatus status;
}

final class PaymentEvent {
  const PaymentEvent({required this.type, required this.message});

  final PaymentEventType type;
  final String message;
}

enum PaymentStatus { authorized, captured, failed, cancelled }

enum PaymentEventType { opened, authorized, failed, cancelled }

@BridgeError('payment_cancelled')
final class PaymentCancelledException extends BridgeException {
  const PaymentCancelledException()
    : super('The customer cancelled the payment.', code: 'payment_cancelled');
}
