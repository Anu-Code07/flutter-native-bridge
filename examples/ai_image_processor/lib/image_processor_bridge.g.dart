// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_processor_bridge.dart';

// **************************************************************************
// BridgeContractGenerator
// **************************************************************************

// ignore_for_file: unused_element, unnecessary_cast, unused_import, unused_field, require_trailing_commas

const Map<String, Object?> _$ImageProcessorBridgeFfiDescriptor =
    <String, Object?>{
  'name': 'ImageProcessorBridge',
  'library': 'nativeflow_image_processor',
  'symbolPrefix': 'nf_image_',
  'threading': 'isolate',
  'methods': <Map<String, Object?>>[
    <String, Object?>{
      'name': 'blur',
      'symbol': 'nf_image_blur',
      'returnType': 'Uint8List',
      'parameters': <Map<String, Object?>>[
        <String, Object?>{
          'name': 'image',
          'type': 'Uint8List',
        },
        <String, Object?>{
          'name': 'radius',
          'type': 'double',
        },
      ],
    },
    <String, Object?>{
      'name': 'enhance',
      'symbol': 'nf_image_enhance',
      'returnType': 'Uint8List',
      'parameters': <Map<String, Object?>>[
        <String, Object?>{
          'name': 'image',
          'type': 'Uint8List',
        },
      ],
    },
  ],
};

final class _$ImageProcessorBridgeClient implements ImageProcessorBridge {
  _$ImageProcessorBridgeClient({
    NativeLibrary? library,
    NativeExecutor? executor,
    Map<String, ImageProcessorBridgeFfiHandler>? handlers,
  })  : _library = library,
        _executor = executor ?? const IsolateNativeExecutor(),
        _handlers =
            handlers ?? const <String, ImageProcessorBridgeFfiHandler>{};

  final NativeLibrary? _library;
  final NativeExecutor _executor;
  final Map<String, ImageProcessorBridgeFfiHandler> _handlers;

  @override
  Uint8List blur(Uint8List image, {double radius = 8}) {
    final handler = _handlers['nf_image_blur'];
    if (handler == null) {
      throw BridgeRegistrationException(
        'FFI symbol "nf_image_blur" has no handler registered. '
        'Register one via the generated client constructor or look it up via _library.',
      );
    }
    final result = handler(<Object?>[image, radius]);
    return result as Uint8List;
  }

  @override
  Uint8List enhance(Uint8List image) {
    final handler = _handlers['nf_image_enhance'];
    if (handler == null) {
      throw BridgeRegistrationException(
        'FFI symbol "nf_image_enhance" has no handler registered. '
        'Register one via the generated client constructor or look it up via _library.',
      );
    }
    final result = handler(<Object?>[image]);
    return result as Uint8List;
  }
}

/// Application-supplied FFI implementation for one [ImageProcessorBridge] symbol.
typedef ImageProcessorBridgeFfiHandler = Object? Function(
    List<Object?> arguments);
