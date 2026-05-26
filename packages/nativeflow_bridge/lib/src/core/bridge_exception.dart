/// Base class for typed errors crossing the Flutter/native boundary.
class BridgeException implements Exception {
  const BridgeException(
    this.message, {
    this.code = 'bridge_error',
    this.details,
    this.platform,
    this.cause,
    this.stackTrace,
  });

  final String code;
  final String message;
  final Object? details;
  final String? platform;
  final Object? cause;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code,
        'message': message,
        'details': details,
        'platform': platform,
      };

  @override
  String toString() => 'BridgeException($code): $message';
}

/// Error raised when a native platform reports a structured bridge failure.
final class BridgePlatformException extends BridgeException {
  const BridgePlatformException(
    super.message, {
    required super.code,
    super.details,
    super.platform,
    super.cause,
    super.stackTrace,
  });
}

/// Error raised when payload encoding or decoding fails.
final class BridgeSerializationException extends BridgeException {
  const BridgeSerializationException(
    super.message, {
    super.cause,
    super.stackTrace,
  }) : super(code: 'serialization_error');
}

/// Error raised when a bridge endpoint cannot be found or registered.
final class BridgeRegistrationException extends BridgeException {
  const BridgeRegistrationException(super.message)
      : super(code: 'registration_error');
}

/// Error raised when a bridge call exceeds its configured timeout.
final class BridgeTimeoutException extends BridgeException {
  const BridgeTimeoutException(super.message) : super(code: 'timeout');
}
