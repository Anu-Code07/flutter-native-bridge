# nativeflow_bridge_runtime

Flutter runtime support for generated NativeFlow Bridge clients, handlers, and
event streams.

This package owns channel execution and stream registration for generated Dart
bridge code. UI code should depend on generated clients rather than using the
runtime directly.

## Usage

```yaml
dependencies:
  nativeflow_bridge_runtime: ^0.1.0
```

Generated bridge clients use this runtime to communicate with platform channel
handlers and event streams.

## Maintainer

Maintained by Anurag in the
[flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge)
repository.
