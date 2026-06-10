# Example bridges

Working examples live under [`examples/`](../examples). They all use the
same `nativeflow_bridge` package the SDK publishes to pub.dev.

| Folder | What it shows |
|--------|----------------|
| `examples/payment_sdk_wrapper` | Payment SDK wrapper (`@Bridge`, `@BridgeMethod`, `@BridgeEvent`, `@BridgeError`). Demonstrates JSON codec, event stream with replay/bufferSize, typed cancellation error. |
| `examples/ai_image_processor` | CPU-heavy image processing via `@FFIBridge`. Demonstrates isolate-based execution and handler dispatch. |
| `examples/kyc_document_capture` | Multi-step native flow with `Stream<KycStep>`, `@BridgeMethod(timeout:)`, and two `@BridgeError` exceptions. |

## Running the generator

```bash
cd examples/payment_sdk_wrapper
dart run build_runner build
```

The generated `*.g.dart` files include:

- `BridgeDescriptor` constants with full metadata (codec, platforms,
  events, errors).
- A private `_$YourBridgeClient` that implements the abstract bridge.
- Kotlin / Swift / Windows C++ / Linux C contract strings.
- For `@FFIBridge`: a typed handler-dispatch client + `…FfiHandler` typedef.

## Inspecting bridge activity

Pair any example with `BridgeInspectorPanel` to see the calls flow:

```dart
import 'package:nativeflow_bridge/devtools.dart';

void showInspector(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: BridgeInspectorPanel()),
    ),
  );
}
```
