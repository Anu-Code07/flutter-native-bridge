# nativeflow_bridge_core

Core transport-neutral primitives shared by NativeFlow Bridge generators and
runtimes.

This package defines descriptors, codecs, serializers, transports, and typed
bridge exceptions. It does not depend on Flutter, so it can be used from Dart
packages that need shared bridge contracts.

## Usage

```dart
import 'package:nativeflow_bridge_core/nativeflow_bridge_core.dart';

final descriptor = BridgeDescriptor(
  name: 'payments',
  channel: 'payments',
  version: 1,
  methods: const <BridgeMethodDescriptor>[],
);
```

## Maintainer

Maintained by Anurag in the
[flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge)
repository.
