# nativeflow_bridge_ffi

Dart FFI runtime primitives for NativeFlow Bridge native libraries and
generated bindings.

Use this package when a bridge needs to load and call native libraries through
Dart FFI instead of Flutter platform channels.

## Usage

```yaml
dependencies:
  nativeflow_bridge_ffi: ^0.1.0
```

Generated FFI bridge code uses this runtime for library loading, memory
handling, and native execution helpers.

## Maintainer

Maintained by Anurag in the
[flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge)
repository.
