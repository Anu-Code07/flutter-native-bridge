/// Redacts sensitive fields from bridge payload previews shown in DevTools.
///
/// Redaction is structural: it walks `Map`/`Iterable` payloads and replaces
/// any value whose key matches a sensitive pattern with the `[REDACTED]`
/// marker. Non-`Map`/`Iterable` payloads pass through untouched.
final class BridgePayloadRedactor {
  BridgePayloadRedactor({Set<Pattern>? sensitiveKeys})
    : _sensitiveKeys = sensitiveKeys ?? _defaultSensitiveKeys;

  static const String redacted = '[REDACTED]';

  static final Set<Pattern> _defaultSensitiveKeys = <Pattern>{
    RegExp(r'pass', caseSensitive: false),
    RegExp(r'secret', caseSensitive: false),
    RegExp(r'token', caseSensitive: false),
    RegExp(r'auth', caseSensitive: false),
    RegExp(r'pan|card|cvv|cvc', caseSensitive: false),
    RegExp(r'pin', caseSensitive: false),
    RegExp(r'ssn|aadhaar|sin', caseSensitive: false),
    RegExp(r'key$', caseSensitive: false),
    RegExp(r'session', caseSensitive: false),
    RegExp(r'cookie', caseSensitive: false),
  };

  final Set<Pattern> _sensitiveKeys;

  Object? redact(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return value.map<Object?, Object?>((key, nestedValue) {
        if (_isSensitive(key)) {
          return MapEntry<Object?, Object?>(key, redacted);
        }
        return MapEntry<Object?, Object?>(key, redact(nestedValue));
      });
    }
    if (value is Iterable && value is! String) {
      return value.map(redact).toList(growable: false);
    }
    return value;
  }

  bool _isSensitive(Object? key) {
    if (key is! String) {
      return false;
    }
    for (final pattern in _sensitiveKeys) {
      if (pattern is RegExp) {
        if (pattern.hasMatch(key)) {
          return true;
        }
      } else if (pattern.allMatches(key).isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
