import 'package:nativeflow_bridge/core.dart';
import 'package:test/test.dart';

void main() {
  test('descriptor serializes stable bridge metadata', () {
    const descriptor = BridgeDescriptor(
      name: 'PaymentBridge',
      channel: 'nativeflow/payments',
      version: 1,
      methods: <BridgeMethodDescriptor>[
        BridgeMethodDescriptor(
          name: 'pay',
          returnType: 'Future<PaymentResult>',
          parameters: <BridgeParameterDescriptor>[
            BridgeParameterDescriptor(
              name: 'request',
              type: 'PaymentRequest',
              isRequired: true,
              isNullable: false,
            ),
          ],
        ),
      ],
      events: <BridgeEventDescriptor>[
        BridgeEventDescriptor(name: 'events', payloadType: 'PaymentEvent'),
      ],
    );

    expect(descriptor.toJson()['channel'], 'nativeflow/payments');
    expect(descriptor.toJson()['version'], 1);
  });

  test('serializer registry delegates custom serializers', () {
    final registry = BridgeSerializerRegistry()
      ..register<int>(_DoubleIntSerializer());

    expect(registry.serialize<int>(4), 8);
    expect(registry.deserialize<int>(10), 5);
    expect(
      registry.serializeValue(<String, Object?>{'count': 4}),
      <String, Object?>{'count': 8},
    );
  });

  test('bridge exceptions expose platform-safe json', () {
    const error = BridgePlatformException(
      'Cancelled',
      code: 'payment_cancelled',
      platform: 'android',
    );

    expect(error.toJson()['code'], 'payment_cancelled');
    expect(error.toString(), contains('payment_cancelled'));
  });
}

final class _DoubleIntSerializer implements BridgeSerializer<int> {
  @override
  Object? serialize(int value) => value * 2;

  @override
  int deserialize(Object? value) => (value! as int) ~/ 2;
}
