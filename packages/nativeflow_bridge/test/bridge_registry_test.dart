import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/runtime.dart';

void main() {
  group('BridgeRegistry', () {
    setUp(() {
      // BridgeRegistry is a singleton; clear via reflection-free re-registration.
      for (final descriptor in BridgeRegistry.instance.descriptors.toList()) {
        // No public clear; rely on duplicate-version detection in tests.
        descriptor.toJson();
      }
    });

    test('registers a descriptor and lets it be looked up', () {
      const descriptor = BridgeDescriptor(
        name: 'AlphaBridge',
        channel: 'nativeflow/alpha',
        version: 1,
        methods: <BridgeMethodDescriptor>[],
      );
      BridgeRegistry.instance.registerDescriptor(descriptor);
      expect(
        BridgeRegistry.instance.descriptors.any(
          (existing) => existing.channel == 'nativeflow/alpha',
        ),
        isTrue,
      );
    });

    test('throws when the same channel is registered with a new version', () {
      const v1 = BridgeDescriptor(
        name: 'BetaBridge',
        channel: 'nativeflow/beta',
        version: 1,
        methods: <BridgeMethodDescriptor>[],
      );
      const v2 = BridgeDescriptor(
        name: 'BetaBridge',
        channel: 'nativeflow/beta',
        version: 2,
        methods: <BridgeMethodDescriptor>[],
      );
      BridgeRegistry.instance.registerDescriptor(v1);
      expect(
        () => BridgeRegistry.instance.registerDescriptor(v2),
        throwsA(isA<BridgeRegistrationException>()),
      );
    });

    test('registers and retrieves plugin instances', () {
      BridgeRegistry.instance.registerPlugin('plugin_a', _FakePlugin('a'));
      final plugin = BridgeRegistry.instance.plugin<_FakePlugin>('plugin_a');
      expect(plugin.name, 'a');
    });

    test('throws when a plugin name is reused', () {
      BridgeRegistry.instance.registerPlugin('plugin_b', _FakePlugin('b'));
      expect(
        () => BridgeRegistry.instance.registerPlugin(
          'plugin_b',
          _FakePlugin('b'),
        ),
        throwsA(isA<BridgeRegistrationException>()),
      );
    });
  });

  group('BridgeErrorMapper', () {
    test('returns BridgePlatformException by default', () {
      final mapper = BridgeErrorMapper();
      final exception = mapper.map(
        _platformException('unknown'),
        StackTrace.current,
      );
      expect(exception, isA<BridgePlatformException>());
      expect(exception.code, 'unknown');
    });

    test('uses registered factories for typed errors', () {
      final mapper = BridgeErrorMapper()
        ..register(
          'custom_failure',
          (error, stackTrace) =>
              const BridgeException('Custom', code: 'custom_failure'),
        );
      final exception = mapper.map(
        _platformException('custom_failure'),
        StackTrace.current,
      );
      expect(exception.code, 'custom_failure');
    });

    test('descriptor errors are surfaced for introspection', () {
      const descriptor = BridgeDescriptor(
        name: 'Gamma',
        channel: 'nativeflow/gamma',
        version: 1,
        methods: <BridgeMethodDescriptor>[],
        errors: <BridgeErrorDescriptor>[
          BridgeErrorDescriptor(code: 'gamma_failure', dartType: 'GammaError'),
        ],
      );
      final mapper = BridgeErrorMapper.fromDescriptor(descriptor);
      expect(mapper.descriptorErrors, hasLength(1));
      expect(mapper.descriptorErrors.first.code, 'gamma_failure');
    });
  });
}

final class _FakePlugin {
  const _FakePlugin(this.name);
  final String name;
}

PlatformException _platformException(String code) =>
    PlatformException(code: code, message: 'platform error: $code');
