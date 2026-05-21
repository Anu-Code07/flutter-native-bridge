import 'dart:convert';
import 'dart:typed_data';

import 'bridge_exception.dart';

/// Encodes bridge payloads before they enter a transport.
abstract interface class BridgeCodec {
  Object? encode(Object? value);

  T? decode<T>(Object? value);
}

/// Codec that keeps platform-channel compatible values unchanged.
final class IdentityBridgeCodec implements BridgeCodec {
  const IdentityBridgeCodec();

  @override
  Object? encode(Object? value) => value;

  @override
  T? decode<T>(Object? value) => value as T?;
}

/// JSON codec for low-friction interop with native SDKs.
final class JsonBridgeCodec implements BridgeCodec {
  const JsonBridgeCodec();

  @override
  Object? encode(Object? value) {
    if (value == null) {
      return null;
    }
    try {
      return jsonEncode(value);
    } on Object catch (error, stackTrace) {
      throw BridgeSerializationException(
        'Failed to encode bridge payload as JSON.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  T? decode<T>(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw BridgeSerializationException(
        'Expected JSON string but received ${value.runtimeType}.',
      );
    }
    try {
      return jsonDecode(value) as T?;
    } on Object catch (error, stackTrace) {
      throw BridgeSerializationException(
        'Failed to decode bridge payload from JSON.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Binary payload wrapper for codecs that operate on bytes.
final class BinaryBridgePayload {
  const BinaryBridgePayload(this.bytes);

  final Uint8List bytes;
}
