import 'package:nativeflow_bridge/core.dart';
import 'package:test/test.dart';

void main() {
  group('BridgeDescriptor', () {
    test('serializes stable bridge metadata', () {
      const descriptor = BridgeDescriptor(
        name: 'PaymentBridge',
        channel: 'nativeflow/payments',
        version: 1,
        codec: BridgeCodecKind.json,
        platforms: <BridgePlatformTarget>[
          BridgePlatformTarget.android,
          BridgePlatformTarget.ios,
        ],
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
          BridgeEventDescriptor(
            name: 'events',
            payloadType: 'PaymentEvent',
            replay: 2,
            bufferSize: 32,
          ),
        ],
        errors: <BridgeErrorDescriptor>[
          BridgeErrorDescriptor(
            code: 'payment_cancelled',
            dartType: 'PaymentCancelledException',
          ),
        ],
      );

      final json = descriptor.toJson();
      expect(json['channel'], 'nativeflow/payments');
      expect(json['version'], 1);
      expect(json['codec'], 'json');
      expect(json['platforms'], <String>['android', 'ios']);
      expect(json['errors'], hasLength(1));
      final events = json['events']! as List<Object?>;
      final firstEvent = events.first! as Map<String, Object?>;
      expect(firstEvent['replay'], 2);
      expect(firstEvent['bufferSize'], 32);
    });

    test('method descriptors expose transport and timeouts', () {
      const method = BridgeMethodDescriptor(
        name: 'pay',
        returnType: 'Future<PaymentResult>',
        transport: BridgeTransport.basicMessageChannel,
        timeoutMilliseconds: 5000,
        parameters: <BridgeParameterDescriptor>[],
      );
      final json = method.toJson();
      expect(json['transport'], 'basicMessageChannel');
      expect(json['timeoutMilliseconds'], 5000);
    });
  });

  group('BridgeSerializerRegistry', () {
    test('delegates registered serializers', () {
      final registry =
          BridgeSerializerRegistry()..register<int>(_DoubleIntSerializer());

      expect(registry.serialize<int>(4), 8);
      expect(registry.deserialize<int>(10), 5);
      expect(
        registry.serializeValue(<String, Object?>{'count': 4}),
        <String, Object?>{'count': 8},
      );
    });

    test('walks nested map/list payloads', () {
      final registry =
          BridgeSerializerRegistry()..register<int>(_DoubleIntSerializer());
      expect(
        registry.serializeValue(<String, Object?>{
          'items': <int>[1, 2, 3],
          'nested': <String, Object?>{'value': 4},
        }),
        <String, Object?>{
          'items': <int>[2, 4, 6],
          'nested': <String, Object?>{'value': 8},
        },
      );
    });

    test('requireSerializer throws when type missing', () {
      final registry = BridgeSerializerRegistry();
      expect(
        () => registry.requireSerializer(Object),
        throwsA(isA<BridgeSerializationException>()),
      );
    });
  });

  group('BridgeException', () {
    test('exposes platform-safe json', () {
      const error = BridgePlatformException(
        'Cancelled',
        code: 'payment_cancelled',
        platform: 'android',
      );

      expect(error.toJson()['code'], 'payment_cancelled');
      expect(error.toString(), contains('payment_cancelled'));
    });

    test('serialization exception uses dedicated code', () {
      const error = BridgeSerializationException('boom');
      expect(error.code, 'serialization_error');
    });

    test('timeout exception uses dedicated code', () {
      const error = BridgeTimeoutException('boom');
      expect(error.code, 'timeout');
    });
  });

  group('BridgeCodec', () {
    test('IdentityBridgeCodec is a pass-through', () {
      const codec = IdentityBridgeCodec();
      expect(codec.encode(42), 42);
      expect(codec.decode<int>(42), 42);
    });

    test('JsonBridgeCodec round-trips structured payloads', () {
      const codec = JsonBridgeCodec();
      final encoded = codec.encode(<String, Object?>{'a': 1});
      expect(encoded, isA<String>());
      final decoded = codec.decode<Map<String, Object?>>(encoded);
      expect(decoded, <String, Object?>{'a': 1});
    });

    test('JsonBridgeCodec rejects non-string decode payloads', () {
      const codec = JsonBridgeCodec();
      expect(
        () => codec.decode<Map<String, Object?>>(42),
        throwsA(isA<BridgeSerializationException>()),
      );
    });
  });
}

final class _DoubleIntSerializer implements BridgeSerializer<int> {
  @override
  Object? serialize(int value) => value * 2;

  @override
  int deserialize(Object? value) => (value! as int) ~/ 2;
}
