import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:nativeflow_bridge/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'model.dart';
import 'native_contract_emitters.dart';

/// Generates Dart bridge clients and machine-readable contract descriptors.
final class BridgeContractGenerator extends Generator {
  static const TypeChecker _bridgeChecker = TypeChecker.typeNamed(
    Bridge,
    inPackage: 'nativeflow_bridge',
  );
  static const TypeChecker _ffiBridgeChecker = TypeChecker.typeNamed(
    FFIBridge,
    inPackage: 'nativeflow_bridge',
  );
  static const TypeChecker _eventChecker = TypeChecker.typeNamed(
    BridgeEvent,
    inPackage: 'nativeflow_bridge',
  );
  static const TypeChecker _methodChecker = TypeChecker.typeNamed(
    BridgeMethod,
    inPackage: 'nativeflow_bridge',
  );

  const BridgeContractGenerator();

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();

    for (final element in library.classes) {
      final bridgeAnnotation = _bridgeChecker.firstAnnotationOf(element);
      final ffiAnnotation = _ffiBridgeChecker.firstAnnotationOf(element);
      if (bridgeAnnotation != null) {
        final contract = _readBridgeContract(element, bridgeAnnotation);
        output
          ..writeln(_emitDescriptor(contract))
          ..writeln(_emitClient(contract))
          ..writeln(_emitNativeContracts(contract));
      }
      if (ffiAnnotation != null) {
        output.writeln(_emitFfiDescriptor(element, ffiAnnotation));
      }
    }

    if (output.isEmpty) {
      return '';
    }
    return '''
// ignore_for_file: unused_element

$output
''';
  }

  BridgeContract _readBridgeContract(
    ClassElement element,
    DartObject annotation,
  ) {
    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@Bridge can only be applied to abstract classes.',
        element: element,
      );
    }

    final reader = ConstantReader(annotation);
    final className = element.name ?? 'AnonymousBridge';
    final channel =
        reader.read('channel').literalValue as String? ??
        _defaultChannelName(className);
    final version = reader.read('version').intValue;
    final operations = element.methods
        .where((method) => !method.isStatic && method.isAbstract)
        .map(_readOperation)
        .toList();

    return BridgeContract(
      name: className,
      channel: channel,
      version: version,
      methods: operations.where((operation) => !operation.isStream).toList(),
      events: operations.where((operation) => operation.isStream).toList(),
    );
  }

  BridgeOperation _readOperation(MethodElement method) {
    final returnType = _typeName(method.returnType);
    final eventAnnotation = _eventChecker.firstAnnotationOf(method);
    final methodAnnotation = _methodChecker.firstAnnotationOf(method);
    final operationName =
        _readNameOverride(eventAnnotation) ??
        _readNameOverride(methodAnnotation) ??
        method.name ??
        'anonymousMethod';

    return BridgeOperation(
      name: operationName,
      returnType: returnType,
      isStream: _isStream(method.returnType),
      timeoutMilliseconds: _readTimeoutMilliseconds(methodAnnotation),
      parameters: method.formalParameters.map(_readParameter).toList(),
    );
  }

  BridgeParameter _readParameter(FormalParameterElement parameter) {
    return BridgeParameter(
      name: parameter.name ?? 'argument',
      type: _typeName(parameter.type),
      isRequired: parameter.isRequiredNamed || parameter.isRequiredPositional,
      isNullable:
          parameter.type.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  String _emitDescriptor(BridgeContract contract) {
    final descriptorName =
        r'_$'
        '${contract.name}Descriptor';
    final buffer = StringBuffer()
      ..writeln('const BridgeDescriptor $descriptorName = BridgeDescriptor(')
      ..writeln("  name: '${contract.name}',")
      ..writeln("  channel: '${contract.channel}',")
      ..writeln('  version: ${contract.version},')
      ..writeln('  methods: <BridgeMethodDescriptor>[');

    for (final method in contract.methods) {
      buffer
        ..writeln('    BridgeMethodDescriptor(')
        ..writeln("      name: '${method.name}',")
        ..writeln("      returnType: '${method.returnType}',")
        ..writeln('      timeoutMilliseconds: ${method.timeoutMilliseconds},')
        ..writeln('      parameters: <BridgeParameterDescriptor>[');
      for (final parameter in method.parameters) {
        buffer
          ..writeln('        BridgeParameterDescriptor(')
          ..writeln("          name: '${parameter.name}',")
          ..writeln("          type: '${parameter.type}',")
          ..writeln('          isRequired: ${parameter.isRequired},')
          ..writeln('          isNullable: ${parameter.isNullable},')
          ..writeln('        ),');
      }
      buffer
        ..writeln('      ],')
        ..writeln('    ),');
    }

    buffer
      ..writeln('  ],')
      ..writeln('  events: <BridgeEventDescriptor>[');

    for (final event in contract.events) {
      buffer
        ..writeln('    BridgeEventDescriptor(')
        ..writeln("      name: '${event.name}',")
        ..writeln(
          "      payloadType: '${_streamPayloadType(event.returnType)}',",
        )
        ..writeln('    ),');
    }

    buffer
      ..writeln('  ],')
      ..writeln(');');
    return buffer.toString();
  }

  String _emitClient(BridgeContract contract) {
    final className =
        r'_$'
        '${contract.name}Client';
    final descriptorName =
        r'_$'
        '${contract.name}Descriptor';
    final buffer = StringBuffer()
      ..writeln('final class $className implements ${contract.name} {')
      ..writeln('  $className({BridgeClient? client})')
      ..writeln('      : _client = client ?? BridgeClient(')
      ..writeln('          descriptor: $descriptorName,')
      ..writeln('        );')
      ..writeln()
      ..writeln('  final BridgeClient _client;')
      ..writeln();

    for (final method in contract.methods) {
      buffer.writeln(_emitMethod(method));
    }

    for (final event in contract.events) {
      buffer.writeln(_emitEvent(event));
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _emitMethod(BridgeOperation method) {
    final parameters = method.parameters.map(_parameterDeclaration).join(', ');
    final arguments = _argumentMap(method.parameters);
    final payloadType = _futurePayloadType(method.returnType);
    final timeout = method.timeoutMilliseconds == null
        ? 'null'
        : 'Duration(milliseconds: ${method.timeoutMilliseconds})';
    return '''
  @override
  ${method.returnType} ${method.name}($parameters) {
    return _client.invoke<$payloadType>(
      '${method.name}',
      arguments: $arguments,
      timeout: $timeout,
    );
  }
''';
  }

  String _emitEvent(BridgeOperation event) {
    final parameters = event.parameters.map(_parameterDeclaration).join(', ');
    final payloadType = _streamPayloadType(event.returnType);
    if (event.parameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Stream bridge methods cannot declare parameters yet. '
        'Use a separate subscribe method for filtered streams.',
      );
    }
    return '''
  @override
  ${event.returnType} ${event.name}($parameters) {
    return _client.events<$payloadType>('${event.name}');
  }
''';
  }

  String _emitNativeContracts(BridgeContract contract) {
    final kotlin = const KotlinContractEmitter().emit(contract);
    final swift = const SwiftContractEmitter().emit(contract);
    final kotlinName =
        r'_$'
        '${contract.name}KotlinContract';
    final swiftName =
        r'_$'
        '${contract.name}SwiftContract';
    return '''
const String $kotlinName = r"""
$kotlin
""";

const String $swiftName = r"""
$swift
""";
''';
  }

  String _emitFfiDescriptor(ClassElement element, DartObject annotation) {
    final reader = ConstantReader(annotation);
    final library = reader.read('library').literalValue as String?;
    final symbolPrefix = reader.read('symbolPrefix').literalValue as String?;
    final className = element.name ?? 'AnonymousFfiBridge';
    final descriptorName =
        r'_$'
        '${className}FfiDescriptor';
    return '''
const Map<String, Object?> $descriptorName = <String, Object?>{
  'name': '$className',
  'library': ${_literalString(library)},
  'symbolPrefix': ${_literalString(symbolPrefix)},
};
''';
  }

  String _parameterDeclaration(BridgeParameter parameter) {
    return '${parameter.type} ${parameter.name}';
  }

  String _argumentMap(List<BridgeParameter> parameters) {
    if (parameters.isEmpty) {
      return 'null';
    }
    final entries = parameters
        .map((parameter) {
          return "'${parameter.name}': ${parameter.name}";
        })
        .join(', ');
    return '<String, Object?>{$entries}';
  }

  String _typeName(DartType type) {
    return type.getDisplayString();
  }

  bool _isStream(DartType type) {
    return _typeName(type).startsWith('Stream<');
  }

  String _streamPayloadType(String returnType) {
    final start = returnType.indexOf('<');
    final end = returnType.lastIndexOf('>');
    if (start == -1 || end <= start) {
      return 'Object?';
    }
    return returnType.substring(start + 1, end);
  }

  String _futurePayloadType(String returnType) {
    if (!returnType.startsWith('Future<')) {
      return returnType;
    }
    final start = returnType.indexOf('<');
    final end = returnType.lastIndexOf('>');
    if (start == -1 || end <= start) {
      return 'Object?';
    }
    return returnType.substring(start + 1, end);
  }

  String? _readNameOverride(DartObject? annotation) {
    if (annotation == null) {
      return null;
    }
    return ConstantReader(annotation).read('name').literalValue as String?;
  }

  int? _readTimeoutMilliseconds(DartObject? annotation) {
    if (annotation == null) {
      return null;
    }
    final timeout = annotation.getField('timeout');
    return timeout?.getField('_duration')?.toIntValue();
  }

  String _defaultChannelName(String className) {
    return 'nativeflow/${className.replaceAll(RegExp(r'Bridge$'), '')}';
  }

  String _literalString(String? value) {
    if (value == null) {
      return 'null';
    }
    return "'$value'";
  }
}
