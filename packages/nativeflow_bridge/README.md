# NativeFlow Bridge

NativeFlow Bridge is the single public package for the NativeFlow Bridge
monorepo. It exports the annotations, generator entrypoints, runtime APIs,
platform package markers, FFI helpers, and DevTools primitives from one import.

Maintained by Anurag at
[Anu-Code07/flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge).

## Usage

```dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

@Bridge(channel: 'payments')
abstract class PaymentBridge {
  Future<void> pay(String requestId);
}
```

The umbrella package exports the core runtime `BridgeCodec` and
`BridgeTransport` names. Annotation-specific codec and transport options are
available as `BridgeAnnotationCodec` and `BridgeAnnotationTransport` to avoid
name collisions:

```dart
@Bridge(codec: BridgeAnnotationCodec.json)
abstract class JsonPaymentBridge {}
```

## Code generation

Add `build_runner` in your app or package and run:

```bash
dart run build_runner build
```

The builder is exposed by this package and delegates to the NativeFlow Bridge
generator package inside the monorepo.
