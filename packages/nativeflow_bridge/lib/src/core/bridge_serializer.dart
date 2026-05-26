import 'bridge_exception.dart';

/// Converts Dart values to transport-safe values and back.
abstract interface class BridgeSerializer<T> {
  Object? serialize(T value);

  T deserialize(Object? value);
}

/// Registry used by generated code for custom and nested serializers.
final class BridgeSerializerRegistry {
  BridgeSerializerRegistry([Map<Type, BridgeSerializer<Object?>>? serializers])
      : _serializers = Map<Type, BridgeSerializer<Object?>>.of(
          serializers ?? const <Type, BridgeSerializer<Object?>>{},
        );

  final Map<Type, BridgeSerializer<Object?>> _serializers;

  void register<T>(BridgeSerializer<T> serializer) {
    _serializers[T] = _CastBridgeSerializer<T>(serializer);
  }

  Object? serialize<T>(T value) {
    if (value == null) {
      return null;
    }
    final serializer = _serializers[T];
    if (serializer == null) {
      return value;
    }
    return serializer.serialize(value);
  }

  Object? serializeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return value.map<Object?, Object?>((key, nestedValue) {
        return MapEntry<Object?, Object?>(key, serializeValue(nestedValue));
      });
    }
    if (value is Iterable && value is! String) {
      return value.map(serializeValue).toList(growable: false);
    }
    final serializer = _serializers[value.runtimeType];
    return serializer == null ? value : serializer.serialize(value);
  }

  T deserialize<T>(Object? value) {
    final serializer = _serializers[T];
    if (serializer == null) {
      return value as T;
    }
    return serializer.deserialize(value) as T;
  }

  T deserializeValue<T>(Object? value) => deserialize<T>(value);

  BridgeSerializer<Object?> requireSerializer(Type type) {
    final serializer = _serializers[type];
    if (serializer == null) {
      throw BridgeSerializationException(
        'No bridge serializer registered for $type.',
      );
    }
    return serializer;
  }
}

final class _CastBridgeSerializer<T> implements BridgeSerializer<Object?> {
  const _CastBridgeSerializer(this.delegate);

  final BridgeSerializer<T> delegate;

  @override
  Object? serialize(Object? value) => delegate.serialize(value as T);

  @override
  Object? deserialize(Object? value) => delegate.deserialize(value);
}
