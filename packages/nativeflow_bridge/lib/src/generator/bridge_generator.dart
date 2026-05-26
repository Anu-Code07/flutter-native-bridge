import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:nativeflow_bridge/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'model.dart';
import 'native_contract_emitters.dart';

/// Generates Dart bridge clients, machine-readable contract descriptors,
/// typed error mappers, and native (Kotlin/Swift/C++) contract strings.
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
  static const TypeChecker _errorChecker = TypeChecker.typeNamed(
    BridgeError,
    inPackage: 'nativeflow_bridge',
  );

  const BridgeContractGenerator();

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();

    final errorBindings = _collectErrorBindings(library);

    for (final element in library.classes) {
      final bridgeAnnotation = _bridgeChecker.firstAnnotationOf(element);
      final ffiAnnotation = _ffiBridgeChecker.firstAnnotationOf(element);
      if (bridgeAnnotation != null) {
        final contract = _readBridgeContract(
          element,
          bridgeAnnotation,
          errorBindings,
        );
        output
          ..writeln(_emitDescriptor(contract))
          ..writeln(_emitClient(contract))
          ..writeln(_emitNativeContracts(contract));
      }
      if (ffiAnnotation != null) {
        final contract = _readFfiContract(element, ffiAnnotation);
        output.writeln(_emitFfiClient(contract));
      }
    }

    if (output.isEmpty) {
      return '';
    }
    return '''
// ignore_for_file: unused_element, unnecessary_cast, unused_import, unused_field, require_trailing_commas

$output
''';
  }

  List<BridgeErrorBinding> _collectErrorBindings(LibraryReader library) {
    final bindings = <BridgeErrorBinding>[];
    for (final element in library.classes) {
      final annotation = _errorChecker.firstAnnotationOf(element);
      if (annotation == null) {
        continue;
      }
      final reader = ConstantReader(annotation);
      final code = reader.read('code').literalValue as String?;
      if (code == null) {
        continue;
      }
      bindings.add(
        BridgeErrorBinding(
          dartType: element.name ?? 'UnknownError',
          code: code,
        ),
      );
    }
    return bindings;
  }

  BridgeContract _readBridgeContract(
    ClassElement element,
    DartObject annotation,
    List<BridgeErrorBinding> errorBindings,
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
    final codec = _readEnumName(reader, 'codec') ?? 'json';
    final platforms = _readEnumList(reader, 'platforms');
    final operations =
        element.methods
            .where((method) => !method.isStatic && method.isAbstract)
            .map(_readOperation)
            .toList();

    return BridgeContract(
      name: className,
      channel: channel,
      version: version,
      methods: operations.where((operation) => !operation.isStream).toList(),
      events: operations.where((operation) => operation.isStream).toList(),
      errors: errorBindings,
      codec: codec,
      platforms:
          platforms.isEmpty
              ? <String>['android', 'ios', 'macos', 'windows', 'linux']
              : platforms,
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

    final transport =
        methodAnnotation == null
            ? 'methodChannel'
            : _readEnumName(ConstantReader(methodAnnotation), 'transport') ??
                'methodChannel';

    final replay =
        eventAnnotation == null
            ? 0
            : (ConstantReader(eventAnnotation).read('replay').intValue);
    final bufferSize =
        eventAnnotation == null
            ? 64
            : (ConstantReader(eventAnnotation).read('bufferSize').intValue);

    return BridgeOperation(
      name: operationName,
      returnType: returnType,
      isStream: _isStream(method.returnType),
      timeoutMilliseconds: _readTimeoutMilliseconds(methodAnnotation),
      transport: transport,
      replay: replay,
      bufferSize: bufferSize,
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
      isNamed: parameter.isNamed,
      isOptionalPositional: parameter.isOptionalPositional,
      defaultValueCode: parameter.defaultValueCode,
    );
  }

  FfiBridgeContract _readFfiContract(
    ClassElement element,
    DartObject annotation,
  ) {
    final reader = ConstantReader(annotation);
    final library = reader.read('library').literalValue as String?;
    final symbolPrefix = reader.read('symbolPrefix').literalValue as String?;
    final threading = _readEnumName(reader, 'threading') ?? 'worker';
    final className = element.name ?? 'AnonymousFfiBridge';

    final methods = <FfiBridgeMethod>[];
    for (final method in element.methods) {
      if (method.isStatic || !method.isAbstract) {
        continue;
      }
      final name = method.name ?? 'anonymousMethod';
      methods.add(
        FfiBridgeMethod(
          name: name,
          returnType: _typeName(method.returnType),
          symbolName: '${symbolPrefix ?? ''}$name',
          parameters: method.formalParameters.map(_readParameter).toList(),
        ),
      );
    }

    return FfiBridgeContract(
      name: className,
      library: library,
      symbolPrefix: symbolPrefix,
      threading: threading,
      methods: methods,
    );
  }

  String _emitDescriptor(BridgeContract contract) {
    final descriptorName =
        r'_$'
        '${contract.name}Descriptor';
    final buffer =
        StringBuffer()
          ..writeln(
            'const BridgeDescriptor $descriptorName = BridgeDescriptor(',
          )
          ..writeln("  name: '${contract.name}',")
          ..writeln("  channel: '${contract.channel}',")
          ..writeln('  version: ${contract.version},')
          ..writeln('  codec: BridgeCodecKind.${contract.codec},')
          ..writeln('  platforms: <BridgePlatformTarget>[')
          ..writeln(
            contract.platforms
                .map((platform) => '    BridgePlatformTarget.$platform,')
                .join('\n'),
          )
          ..writeln('  ],')
          ..writeln('  methods: <BridgeMethodDescriptor>[');

    for (final method in contract.methods) {
      buffer
        ..writeln('    BridgeMethodDescriptor(')
        ..writeln("      name: '${method.name}',")
        ..writeln("      returnType: '${method.returnType}',")
        ..writeln('      transport: BridgeTransport.${method.transport},')
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
        ..writeln('      replay: ${event.replay},')
        ..writeln('      bufferSize: ${event.bufferSize},')
        ..writeln('    ),');
    }

    buffer
      ..writeln('  ],')
      ..writeln('  errors: <BridgeErrorDescriptor>[');
    for (final error in contract.errors) {
      buffer
        ..writeln('    BridgeErrorDescriptor(')
        ..writeln("      code: '${error.code}',")
        ..writeln("      dartType: '${error.dartType}',")
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
    final codecExpression = _codecExpression(contract.codec);
    final buffer =
        StringBuffer()
          ..writeln('final class $className implements ${contract.name} {')
          ..writeln('  $className({')
          ..writeln('    BridgeClient? client,')
          ..writeln('    BridgeSerializerRegistry? serializers,')
          ..writeln('  }) : _client = client ??')
          ..writeln('            BridgeClient(')
          ..writeln('              descriptor: $descriptorName,')
          ..writeln('              codec: $codecExpression,')
          ..writeln('              serializers: serializers,')
          ..writeln('              errorMapper: _buildErrorMapper(),')
          ..writeln('            );')
          ..writeln()
          ..writeln('  final BridgeClient _client;')
          ..writeln();

    for (final method in contract.methods) {
      buffer.writeln(_emitMethod(method));
    }

    for (final event in contract.events) {
      buffer.writeln(_emitEvent(event));
    }

    buffer
      ..writeln('  static BridgeErrorMapper _buildErrorMapper() {')
      ..writeln(
        '    final mapper = BridgeErrorMapper.fromDescriptor($descriptorName);',
      );
    for (final error in contract.errors) {
      buffer
        ..writeln("    mapper.register('${error.code}', (error, stackTrace) {")
        ..writeln('      try {')
        ..writeln('        return ${error.dartType}();')
        ..writeln('      } on NoSuchMethodError {')
        ..writeln('        return BridgePlatformException(')
        ..writeln("          error.message ?? '${error.dartType} reported.',")
        ..writeln('          code: error.code,')
        ..writeln('          details: error.details,')
        ..writeln('          cause: error,')
        ..writeln('          stackTrace: stackTrace,')
        ..writeln('        );')
        ..writeln('      }')
        ..writeln('    });');
    }
    buffer
      ..writeln('    return mapper;')
      ..writeln('  }')
      ..writeln('}');
    return buffer.toString();
  }

  String _emitMethod(BridgeOperation method) {
    final parameters = _formalParameterList(method.parameters);
    final arguments = _argumentMap(method.parameters);
    final payloadType = _futurePayloadType(method.returnType);
    final timeout =
        method.timeoutMilliseconds == null
            ? 'null'
            : 'const Duration(milliseconds: ${method.timeoutMilliseconds})';
    final transportCall = switch (method.transport) {
      'basicMessageChannel' => '''
    return _client.send<$payloadType>(
      '${method.name}',
      message: $arguments,
      timeout: $timeout,
    );''',
      _ => '''
    return _client.invoke<$payloadType>(
      '${method.name}',
      arguments: $arguments,
      timeout: $timeout,
    );''',
    };
    return '''
  @override
  ${method.returnType} ${method.name}($parameters) {
$transportCall
  }
''';
  }

  String _emitEvent(BridgeOperation event) {
    final parameters = _formalParameterList(event.parameters);
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
    final emitters = <String, NativeContractEmitter>{
      'android': const KotlinContractEmitter(),
      'macos': const SwiftContractEmitter(),
      'ios': const SwiftContractEmitter(),
      'windows': const WindowsCppContractEmitter(),
      'linux': const LinuxCppContractEmitter(),
    };
    final buffer = StringBuffer();
    final platforms = contract.platforms;
    if (platforms.contains('android')) {
      buffer.writeln(
        _emitContractConstant(
          suffix: 'KotlinContract',
          contract: contract,
          body: emitters['android']!.emit(contract),
        ),
      );
    }
    if (platforms.contains('ios') || platforms.contains('macos')) {
      buffer.writeln(
        _emitContractConstant(
          suffix: 'SwiftContract',
          contract: contract,
          body: emitters['ios']!.emit(contract),
        ),
      );
    }
    if (platforms.contains('windows')) {
      buffer.writeln(
        _emitContractConstant(
          suffix: 'WindowsContract',
          contract: contract,
          body: emitters['windows']!.emit(contract),
        ),
      );
    }
    if (platforms.contains('linux')) {
      buffer.writeln(
        _emitContractConstant(
          suffix: 'LinuxContract',
          contract: contract,
          body: emitters['linux']!.emit(contract),
        ),
      );
    }
    return buffer.toString();
  }

  String _emitContractConstant({
    required String suffix,
    required BridgeContract contract,
    required String body,
  }) {
    final name =
        r'_$'
        '${contract.name}$suffix';
    return 'const String $name = r"""\n$body\n""";';
  }

  String _emitFfiClient(FfiBridgeContract contract) {
    final descriptorName =
        r'_$'
        '${contract.name}FfiDescriptor';
    final clientName =
        r'_$'
        '${contract.name}Client';
    final symbolPrefix =
        contract.symbolPrefix == null ? "''" : "'${contract.symbolPrefix}'";
    final libraryLiteral =
        contract.library == null ? 'null' : "'${contract.library}'";

    final buffer =
        StringBuffer()
          ..writeln(
            'const Map<String, Object?> $descriptorName = <String, Object?>{',
          )
          ..writeln("  'name': '${contract.name}',")
          ..writeln("  'library': $libraryLiteral,")
          ..writeln("  'symbolPrefix': $symbolPrefix,")
          ..writeln("  'threading': '${contract.threading}',")
          ..writeln("  'methods': <Map<String, Object?>>[");
    for (final method in contract.methods) {
      buffer
        ..writeln('    <String, Object?>{')
        ..writeln("      'name': '${method.name}',")
        ..writeln("      'symbol': '${method.symbolName}',")
        ..writeln("      'returnType': '${method.returnType}',")
        ..writeln("      'parameters': <Map<String, Object?>>[");
      for (final parameter in method.parameters) {
        buffer
          ..writeln('        <String, Object?>{')
          ..writeln("          'name': '${parameter.name}',")
          ..writeln("          'type': '${parameter.type}',")
          ..writeln('        },');
      }
      buffer
        ..writeln('      ],')
        ..writeln('    },');
    }
    buffer
      ..writeln('  ],')
      ..writeln('};')
      ..writeln()
      ..writeln('final class $clientName implements ${contract.name} {')
      ..writeln('  $clientName({')
      ..writeln('    NativeLibrary? library,')
      ..writeln('    NativeExecutor? executor,')
      ..writeln('    Map<String, ${contract.name}FfiHandler>? handlers,')
      ..writeln('  })  : _library = library,')
      ..writeln(
        '        _executor = executor ?? ${_ffiExecutor(contract.threading)},',
      )
      ..writeln(
        '        _handlers = handlers ?? const <String, ${contract.name}FfiHandler>{};',
      )
      ..writeln()
      ..writeln('  final NativeLibrary? _library;')
      ..writeln('  final NativeExecutor _executor;')
      ..writeln('  final Map<String, ${contract.name}FfiHandler> _handlers;')
      ..writeln();
    for (final method in contract.methods) {
      buffer.writeln(_emitFfiMethod(method));
    }
    buffer.writeln('}');

    buffer
      ..writeln()
      ..writeln(
        '/// Application-supplied FFI implementation for one [${contract.name}] symbol.',
      )
      ..writeln(
        'typedef ${contract.name}FfiHandler = Object? Function(List<Object?> arguments);',
      );

    return buffer.toString();
  }

  String _emitFfiMethod(FfiBridgeMethod method) {
    final parameters = _formalParameterList(method.parameters);
    final positional =
        method.parameters.map((parameter) => parameter.name).toList();
    return '''
  @override
  ${method.returnType} ${method.name}($parameters) {
    final handler = _handlers['${method.symbolName}'];
    if (handler == null) {
      throw BridgeRegistrationException(
        'FFI symbol "${method.symbolName}" has no handler registered. '
        'Register one via the generated client constructor or look it up via _library.',
      );
    }
    final result = handler(<Object?>[${positional.join(', ')}]);
    return result as ${method.returnType};
  }
''';
  }

  String _ffiExecutor(String threading) => switch (threading) {
    'main' => 'const InlineNativeExecutor()',
    'isolate' => 'const IsolateNativeExecutor()',
    _ => 'const IsolateNativeExecutor()',
  };

  String _formalParameterList(List<BridgeParameter> parameters) {
    if (parameters.isEmpty) {
      return '';
    }
    final positional = <String>[];
    final optionalPositional = <String>[];
    final named = <String>[];
    for (final parameter in parameters) {
      final declaration = '${parameter.type} ${parameter.name}';
      final defaultSuffix =
          parameter.defaultValueCode == null || parameter.isRequired
              ? ''
              : ' = ${parameter.defaultValueCode}';
      if (parameter.isNamed) {
        if (parameter.isRequired) {
          named.add('required $declaration');
        } else {
          named.add('$declaration$defaultSuffix');
        }
      } else if (parameter.isOptionalPositional) {
        optionalPositional.add('$declaration$defaultSuffix');
      } else {
        positional.add(declaration);
      }
    }
    final segments = <String>[];
    if (positional.isNotEmpty) {
      segments.add(positional.join(', '));
    }
    if (optionalPositional.isNotEmpty) {
      segments.add('[${optionalPositional.join(', ')}]');
    }
    if (named.isNotEmpty) {
      segments.add('{${named.join(', ')}}');
    }
    return segments.join(', ');
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

  String _codecExpression(String codec) => switch (codec) {
    'json' => 'const JsonBridgeCodec()',
    'identity' => 'const IdentityBridgeCodec()',
    _ => 'const IdentityBridgeCodec()',
  };

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

  String? _readEnumName(ConstantReader reader, String field) {
    final value = reader.read(field);
    if (value.isNull) {
      return null;
    }
    final symbol = value.objectValue.getField('_name')?.toStringValue();
    return symbol;
  }

  List<String> _readEnumList(ConstantReader reader, String field) {
    final list = reader.read(field);
    if (list.isNull) {
      return const <String>[];
    }
    final values = list.listValue;
    return values
        .map((value) => value.getField('_name')?.toStringValue())
        .whereType<String>()
        .toList();
  }

  String _defaultChannelName(String className) {
    return 'nativeflow/${className.replaceAll(RegExp(r'Bridge$'), '')}';
  }
}
