// Payment SDK wrapper — platform channel bridge with methods and events.
//
// Run: dart run example/payment_bridge_example.dart
//
// In your app, add `part 'payment_bridge.g.dart';` and run build_runner.
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

@Bridge(channel: 'myapp/payments', version: 1)
abstract class PaymentBridge {
  Future<void> pay(String orderId, int amountMinor);

  @BridgeEvent(name: 'status')
  Stream<String> paymentStatus();
}

@BridgeError('payment_cancelled')
final class PaymentCancelledException extends BridgeException {
  const PaymentCancelledException()
      : super('User cancelled checkout.', code: 'payment_cancelled');
}

void main() {
  print('Payment bridge contract');
  print('  channel: myapp/payments');
  print('  methods: pay, cancel (add in your app)');
  print('  events:  paymentStatus stream');
  print('');
  print('Next: copy this file into your app, add part + build_runner,');
  print('then implement PaymentBridgeNativeBridge in Kotlin/Swift.');
}
