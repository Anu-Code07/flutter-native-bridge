@TestOn('vm')
library;

import 'package:nativeflow_bridge/src/generator/model.dart';
import 'package:nativeflow_bridge/src/generator/native_contract_emitters.dart';
import 'package:test/test.dart';

const BridgeContract _contract = BridgeContract(
  name: 'PaymentBridge',
  channel: 'nativeflow/payments',
  version: 1,
  codec: 'json',
  platforms: <String>['android', 'ios', 'windows', 'linux'],
  methods: <BridgeOperation>[
    BridgeOperation(
      name: 'pay',
      returnType: 'Future<Map<String, Object?>>',
      isStream: false,
      transport: 'methodChannel',
      parameters: <BridgeParameter>[
        BridgeParameter(
          name: 'request',
          type: 'Map<String, Object?>',
          isRequired: true,
          isNullable: false,
        ),
      ],
    ),
  ],
  events: <BridgeOperation>[
    BridgeOperation(
      name: 'events',
      returnType: 'Stream<Map<String, Object?>>',
      isStream: true,
      transport: 'eventChannel',
      replay: 1,
      bufferSize: 64,
      parameters: <BridgeParameter>[],
    ),
  ],
  errors: <BridgeErrorBinding>[
    BridgeErrorBinding(
      dartType: 'PaymentCancelledException',
      code: 'payment_cancelled',
    ),
  ],
);

void main() {
  test('KotlinContractEmitter produces an interface + error constants', () {
    final output = const KotlinContractEmitter().emit(_contract);
    expect(output, contains('interface PaymentBridgeNativeBridge'));
    expect(output, contains('suspend fun pay'));
    expect(output, contains('fun events(): Flow<Map<String, Any?>>'));
    expect(output, contains('object PaymentBridgeErrors'));
    expect(output, contains('PAYMENT_CANCELLED = "payment_cancelled"'));
  });

  test('SwiftContractEmitter produces a protocol + error enum', () {
    final output = const SwiftContractEmitter().emit(_contract);
    expect(output, contains('protocol PaymentBridgeNativeBridge'));
    expect(output, contains('func pay(request: [String: Any?]) async throws'));
    expect(output, contains('func events() -> AnyPublisher'));
    expect(output, contains('enum PaymentBridgeErrors'));
    expect(output, contains('paymentCancelled = "payment_cancelled"'));
  });

  test('WindowsCppContractEmitter emits virtual handlers', () {
    final output = const WindowsCppContractEmitter().emit(_contract);
    expect(output, contains('class PaymentBridgeNativeBridge'));
    expect(output, contains('virtual void pay'));
    expect(output, contains('flutter::EncodableValue'));
  });

  test('LinuxCppContractEmitter emits a typedef struct', () {
    final output = const LinuxCppContractEmitter().emit(_contract);
    expect(output, contains('flutter_linux/flutter_linux.h'));
    expect(output, contains('PaymentBridgeNativeBridge'));
    expect(output, contains('void (*pay)'));
  });
}
