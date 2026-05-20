import 'model.dart';

/// Emits Kotlin interfaces implemented by Android plugin adapters.
final class KotlinContractEmitter {
  const KotlinContractEmitter();

  String emit(BridgeContract contract) {
    final buffer = StringBuffer()
      ..writeln('package nativeflow.generated')
      ..writeln()
      ..writeln('import kotlinx.coroutines.flow.Flow')
      ..writeln()
      ..writeln('interface ${contract.name}NativeBridge {');

    for (final method in contract.methods) {
      final parameters = method.parameters
          .map(
            (parameter) => '${parameter.name}: ${_kotlinType(parameter.type)}',
          )
          .join(', ');
      buffer.writeln(
        '  suspend fun ${method.name}($parameters): ${_kotlinType(method.returnType)}',
      );
    }

    for (final event in contract.events) {
      buffer.writeln(
        '  fun ${event.name}(): Flow<${_streamPayload(event.returnType, _kotlinType)}>',
      );
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _kotlinType(String dartType) => switch (_normalizeType(dartType)) {
        'void' => 'Unit',
        'bool' => 'Boolean',
        'int' => 'Long',
        'double' => 'Double',
        'String' => 'String',
        'Uint8List' => 'ByteArray',
        _ => 'Map<String, Any?>',
      };
}

/// Emits Swift protocols implemented by iOS/macOS plugin adapters.
final class SwiftContractEmitter {
  const SwiftContractEmitter();

  String emit(BridgeContract contract) {
    final buffer = StringBuffer()
      ..writeln('import Combine')
      ..writeln('import Foundation')
      ..writeln()
      ..writeln('protocol ${contract.name}NativeBridge {');

    for (final method in contract.methods) {
      final parameters = method.parameters
          .map(
            (parameter) => '${parameter.name}: ${_swiftType(parameter.type)}',
          )
          .join(', ');
      buffer.writeln(
        '  func ${method.name}($parameters) async throws -> ${_swiftType(method.returnType)}',
      );
    }

    for (final event in contract.events) {
      buffer.writeln(
        '  func ${event.name}() -> AnyPublisher<${_streamPayload(event.returnType, _swiftType)}, Error>',
      );
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _swiftType(String dartType) => switch (_normalizeType(dartType)) {
        'void' => 'Void',
        'bool' => 'Bool',
        'int' => 'Int64',
        'double' => 'Double',
        'String' => 'String',
        'Uint8List' => 'Data',
        _ => '[String: Any?]',
      };
}

String _streamPayload(String returnType, String Function(String) mapper) {
  final start = returnType.indexOf('<');
  final end = returnType.lastIndexOf('>');
  if (start == -1 || end == -1 || end <= start) {
    return mapper('Object');
  }
  return mapper(returnType.substring(start + 1, end));
}

String _normalizeType(String dartType) {
  return dartType
      .replaceAll('Future<', '')
      .replaceAll('Stream<', '')
      .replaceAll('?>', '>')
      .replaceAll('?', '')
      .replaceAll('>', '')
      .trim();
}
