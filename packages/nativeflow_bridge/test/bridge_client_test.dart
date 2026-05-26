import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/devtools.dart';
import 'package:nativeflow_bridge/runtime.dart';

const BridgeDescriptor _descriptor = BridgeDescriptor(
  name: 'TestBridge',
  channel: 'nativeflow/test',
  version: 1,
  methods: <BridgeMethodDescriptor>[
    BridgeMethodDescriptor(
      name: 'echo',
      returnType: 'Future<String>',
      parameters: <BridgeParameterDescriptor>[],
    ),
    BridgeMethodDescriptor(
      name: 'fail',
      returnType: 'Future<void>',
      parameters: <BridgeParameterDescriptor>[],
    ),
    BridgeMethodDescriptor(
      name: 'slow',
      returnType: 'Future<void>',
      parameters: <BridgeParameterDescriptor>[],
    ),
  ],
  events: <BridgeEventDescriptor>[
    BridgeEventDescriptor(name: 'pulses', payloadType: 'int', replay: 2),
  ],
  errors: <BridgeErrorDescriptor>[
    BridgeErrorDescriptor(code: 'custom_failure', dartType: 'CustomFailure'),
  ],
);

final class CustomFailure extends BridgeException {
  const CustomFailure() : super('Custom failure.', code: 'custom_failure');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BridgeInspector inspector;

  setUp(() {
    inspector =
        BridgeInspector.instance
          ..clear()
          ..isEnabled = true
          ..capturePayloads = false
          ..vmServiceBroadcast = false;
  });

  void registerMethodHandler(
    Future<Object?>? Function(MethodCall call) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('nativeflow/test'),
          handler,
        );
  }

  tearDown(() {
    registerMethodHandler((_) async => null);
  });

  test('invoke decodes platform channel responses', () async {
    registerMethodHandler((call) async {
      if (call.method == 'echo') {
        return 'pong';
      }
      return null;
    });

    final client = BridgeClient(descriptor: _descriptor, inspector: inspector);

    final result = await client.invoke<String>('echo');
    expect(result, 'pong');
    expect(inspector.timeline.last.status, BridgeOperationStatus.success);
    expect(inspector.stats.single.totalCalls, 1);
  });

  test('invoke maps PlatformException through error mapper', () async {
    registerMethodHandler((call) async {
      throw PlatformException(code: 'custom_failure', message: 'nope');
    });

    final client = BridgeClient(
      descriptor: _descriptor,
      inspector: inspector,
      errorMapper: BridgeErrorMapper.fromDescriptor(_descriptor)..register(
        'custom_failure',
        (error, stackTrace) => const CustomFailure(),
      ),
    );

    await expectLater(
      client.invoke<void>('fail'),
      throwsA(isA<CustomFailure>()),
    );
    expect(inspector.timeline.last.status, BridgeOperationStatus.error);
    expect(inspector.timeline.last.errorCode, 'custom_failure');
  });

  test('invoke maps timeouts to BridgeTimeoutException', () async {
    registerMethodHandler((call) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return null;
    });

    final client = BridgeClient(descriptor: _descriptor, inspector: inspector);

    await expectLater(
      client.invoke<void>('slow', timeout: const Duration(milliseconds: 5)),
      throwsA(isA<BridgeTimeoutException>()),
    );
    expect(inspector.timeline.last.status, BridgeOperationStatus.timeout);
  });

  test('payload preview is captured only when enabled', () async {
    inspector.capturePayloads = true;
    registerMethodHandler((call) async => 'pong');

    final client = BridgeClient(descriptor: _descriptor, inspector: inspector);

    await client.invoke<String>('echo');
    final completed = inspector.timeline.last;
    expect(completed.responsePreview, 'pong');
  });

  test('payload redactor strips sensitive fields', () {
    final redactor = BridgePayloadRedactor();
    final redacted = redactor.redact(<String, Object?>{
      'orderId': 'ord_1',
      'apiToken': 'secret',
      'card': <String, Object?>{'pan': '4111111111111111', 'expiry': '12/30'},
    });
    expect(redacted, <String, Object?>{
      'orderId': 'ord_1',
      'apiToken': '[REDACTED]',
      'card': '[REDACTED]',
    });
  });
}
