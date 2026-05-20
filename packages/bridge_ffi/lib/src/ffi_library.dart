import 'dart:ffi';
import 'dart:io';

import 'package:nativeflow_bridge_core/bridge_core.dart';

/// Resolves dynamic libraries consistently across Flutter desktop/mobile.
final class NativeLibraryResolver {
  const NativeLibraryResolver();

  DynamicLibrary open(String name) {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        return DynamicLibrary.process();
      }
      return DynamicLibrary.open(_platformLibraryName(name));
    } on Object catch (error, stackTrace) {
      throw BridgeRegistrationException(
        'Unable to open native library "$name": $error\n$stackTrace',
      );
    }
  }

  String _platformLibraryName(String name) {
    if (Platform.isWindows) {
      return '$name.dll';
    }
    if (Platform.isLinux || Platform.isAndroid) {
      return 'lib$name.so';
    }
    return 'lib$name.dylib';
  }
}

/// Typed symbol lookup facade used by generated FFI clients.
final class NativeLibrary {
  NativeLibrary({
    required String name,
    NativeLibraryResolver resolver = const NativeLibraryResolver(),
  }) : _library = resolver.open(name);

  final DynamicLibrary _library;

  Pointer<T> lookupPointer<T extends NativeType>(String symbol) {
    try {
      return _library.lookup<T>(symbol);
    } on Object catch (error, stackTrace) {
      throw BridgeRegistrationException(
        'Native symbol "$symbol" was not found: $error\n$stackTrace',
      );
    }
  }
}
