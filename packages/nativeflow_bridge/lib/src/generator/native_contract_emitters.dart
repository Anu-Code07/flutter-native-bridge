import 'model.dart';

/// Common interface for per-platform native contract emitters.
abstract interface class NativeContractEmitter {
  String emit(BridgeContract contract);
}

/// Emits Kotlin interfaces implemented by Android plugin adapters.
final class KotlinContractEmitter implements NativeContractEmitter {
  const KotlinContractEmitter();

  @override
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

    if (contract.errors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('object ${contract.name}Errors {');
      for (final error in contract.errors) {
        buffer.writeln('  const val ${_constName(error.code)} = "${error.code}"');
      }
      buffer.writeln('}');
    }
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
final class SwiftContractEmitter implements NativeContractEmitter {
  const SwiftContractEmitter();

  @override
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

    if (contract.errors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('enum ${contract.name}Errors {');
      for (final error in contract.errors) {
        buffer.writeln(
          '  static let ${_camelCase(error.code)} = "${error.code}"',
        );
      }
      buffer.writeln('}');
    }
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

/// Emits a C++ handler stub for Windows plugins.
final class WindowsCppContractEmitter implements NativeContractEmitter {
  const WindowsCppContractEmitter();

  @override
  String emit(BridgeContract contract) {
    final buffer = StringBuffer()
      ..writeln('// Auto-generated NativeFlow Bridge Windows contract.')
      ..writeln('#pragma once')
      ..writeln()
      ..writeln('#include <flutter/encodable_value.h>')
      ..writeln('#include <flutter/method_call.h>')
      ..writeln('#include <flutter/method_result.h>')
      ..writeln('#include <memory>')
      ..writeln('#include <string>')
      ..writeln()
      ..writeln('namespace nativeflow_generated {')
      ..writeln()
      ..writeln('class ${contract.name}NativeBridge {')
      ..writeln(' public:')
      ..writeln('  virtual ~${contract.name}NativeBridge() = default;');
    for (final method in contract.methods) {
      buffer.writeln(
        '  virtual void ${method.name}(const flutter::EncodableValue& arguments, '
        'std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;',
      );
    }
    buffer
      ..writeln('};')
      ..writeln()
      ..writeln('} // namespace nativeflow_generated');
    return buffer.toString();
  }
}

/// Emits a C++ handler stub for Linux plugins.
final class LinuxCppContractEmitter implements NativeContractEmitter {
  const LinuxCppContractEmitter();

  @override
  String emit(BridgeContract contract) {
    final buffer = StringBuffer()
      ..writeln('// Auto-generated NativeFlow Bridge Linux contract.')
      ..writeln('#pragma once')
      ..writeln()
      ..writeln('#include <flutter_linux/flutter_linux.h>')
      ..writeln()
      ..writeln('typedef struct {')
      ..writeln('  const gchar* channel;');
    for (final method in contract.methods) {
      buffer.writeln(
        '  void (*${method.name})(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);',
      );
    }
    buffer
      ..writeln('} ${contract.name}NativeBridge;')
      ..writeln();
    return buffer.toString();
  }
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

String _constName(String code) {
  return code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
}

String _camelCase(String value) {
  final parts = value.split(RegExp(r'[^A-Za-z0-9]+'));
  if (parts.isEmpty) {
    return value;
  }
  final first = parts.first.toLowerCase();
  final rest = parts.skip(1).map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  });
  return ([first, ...rest]).join();
}
