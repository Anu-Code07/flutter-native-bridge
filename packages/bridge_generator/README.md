# nativeflow_bridge_generator

Source generation for NativeFlow Bridge Dart clients and native platform
contracts.

Use this package as a development dependency with `build_runner`. It reads
annotations from `nativeflow_bridge_annotations` and emits generated bridge
clients, descriptors, and native contract metadata.

## Usage

```yaml
dev_dependencies:
  build_runner: ^2.4.15
  nativeflow_bridge_generator: ^0.1.0
```

Run generation with:

```bash
dart run build_runner build
```

## Maintainer

Maintained by Anurag in the
[flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge)
repository.
