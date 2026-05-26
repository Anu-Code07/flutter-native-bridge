import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nativeflow_bridge/core.dart';

/// Builds a [BridgeException] from a native [PlatformException].
typedef BridgeErrorFactory =
    BridgeException Function(PlatformException error, StackTrace stackTrace);

/// Maps native error codes to strongly-typed Dart exceptions.
///
/// Generators populate the mapper from `@BridgeError`-annotated classes in the
/// user's bridge file. Application code can also register additional
/// factories at runtime.
final class BridgeErrorMapper {
  BridgeErrorMapper({Map<String, BridgeErrorFactory>? factories})
    : _factories = Map<String, BridgeErrorFactory>.of(
        factories ?? const <String, BridgeErrorFactory>{},
      );

  /// Builds a mapper that already knows about `descriptor.errors`. Callers
  /// usually layer additional [register] calls on top of this base mapper.
  factory BridgeErrorMapper.fromDescriptor(BridgeDescriptor descriptor) {
    final mapper = BridgeErrorMapper();
    for (final error in descriptor.errors) {
      mapper._descriptorErrors[error.code] = error;
    }
    return mapper;
  }

  final Map<String, BridgeErrorFactory> _factories;
  final Map<String, BridgeErrorDescriptor> _descriptorErrors =
      <String, BridgeErrorDescriptor>{};

  /// Registers a typed exception factory for a native error [code].
  void register(String code, BridgeErrorFactory factory) {
    _factories[code] = factory;
  }

  /// Maps [error] to a [BridgeException]. Falls back to a generic
  /// [BridgePlatformException] when no specific factory is registered.
  BridgeException map(PlatformException error, StackTrace stackTrace) {
    final factory = _factories[error.code];
    if (factory != null) {
      return factory(error, stackTrace);
    }
    return BridgePlatformException(
      error.message ?? 'Native bridge call failed.',
      code: error.code,
      details: error.details,
      platform: defaultTargetPlatform.name,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Snapshot of the descriptor-declared error contract for introspection.
  List<BridgeErrorDescriptor> get descriptorErrors =>
      List<BridgeErrorDescriptor>.unmodifiable(_descriptorErrors.values);
}
