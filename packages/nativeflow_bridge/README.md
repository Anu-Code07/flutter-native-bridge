# NativeFlow Bridge

Type-safe Flutter ↔ native bridges. Replace hand-written `MethodChannel` and
`EventChannel` boilerplate with annotated APIs, `build_runner` codegen, a
shared runtime for Android, iOS, macOS, Windows, and Linux, and a built-in
DevTools-grade inspector for every bridge call.

**Supports Flutter 3.44+** (Dart 3.7+).

## What you solve

| Without NativeFlow Bridge | With NativeFlow Bridge |
|-------------------------|------------------------|
| String method names and `Map` arguments | Typed `Future` / `Stream` on a Dart interface |
| Separate EventChannel setup per feature | `@BridgeEvent` on the same contract |
| Dart, Kotlin, and Swift drift apart | Generated **Kotlin/Swift/Windows/Linux contracts** from one `@Bridge` |
| `try/catch (PlatformException)` everywhere | `@BridgeError('code') class … extends BridgeException` |
| Blind debugging of native channels | In-app `BridgeInspectorPanel` + DevTools live timeline |
| Channel glue scattered in UI/widgets | Generated client → repository/BLoC → native SDK |

## When to use it

- Wrapping a **payment, KYC, maps, or device SDK** that only ships native Android/iOS libraries
- **Brownfield** apps: existing Kotlin/Swift modules called from Flutter
- **Many methods + live events** (payment status, downloads, BLE, GPS feeds)
- **FFI** for C/C++/Rust (image processing, on-device ML, crypto)

## Install

```yaml
dependencies:
  nativeflow_bridge: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.15
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quick start

**1. Define a bridge** (`lib/bridges/device_bridge.dart`):

```dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'device_bridge.g.dart';

@Bridge(channel: 'myapp/device', version: 1)
abstract class DeviceBridge {
  Future<bool> connect(String deviceId);
  Future<void> disconnect();

  @BridgeEvent(name: 'telemetry', replay: 1, bufferSize: 32)
  Stream<DeviceTelemetry> telemetry();
}
```

**2. Generate** → `device_bridge.g.dart` contains `_$DeviceBridgeClient`, a
`BridgeDescriptor`, a typed `BridgeErrorMapper`, and native contract strings
for Kotlin / Swift / Windows C++ / Linux C.

**3. Call from your app** (repository, not widgets):

```dart
final device = _$DeviceBridgeClient();
await device.connect('ble:abc');
device.telemetry().listen((t) => /* update state */);
```

**4. Inspect everything** — drop the inspector panel into a debug route:

```dart
import 'package:nativeflow_bridge/devtools.dart';

if (kDebugMode) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: BridgeInspectorPanel()),
  ));
}
```

You will see a live timeline, per-channel latency stats, an error feed, and
a one-click JSON export. Payload previews are off by default; opt in with
`BridgeInspector.instance.capturePayloads = true` — sensitive fields are
redacted automatically.

## DevTools integration

NativeFlow Bridge ships a first-class DevTools experience:

- `BridgeInspector.instance.events` is a broadcast `Stream<BridgeTimelineEvent>`
  you can pipe into any UI, log sink, or analytics pipeline.
- `BridgeDevToolsService.register()` exposes
  `ext.nativeflow_bridge.timeline / stats / config / clear` VM-service
  extensions so Dart DevTools (or the NativeFlow Bridge DevTools extension)
  can pull data live.
- Every event is also published via
  `developer.postEvent('nativeflow_bridge.timeline', …)`.
- All telemetry is metadata-first (size, duration, transport, error code).
  Raw payload inspection is opt-in and passes through
  `BridgePayloadRedactor`.

## Example 1 — Payment SDK (platform channels)

```dart
@Bridge(channel: 'myapp/payments', version: 1, codec: BridgeCodec.json)
abstract class PaymentBridge {
  Future<PaymentResult> pay(PaymentRequest request);

  @BridgeEvent(name: 'events', replay: 1, bufferSize: 64)
  Stream<PaymentEvent> events();

  @BridgeMethod(timeout: Duration(seconds: 30))
  Future<void> cancelPayment();
}

@BridgeError('payment_cancelled')
final class PaymentCancelledException extends BridgeException {
  const PaymentCancelledException()
      : super('Payment cancelled.', code: 'payment_cancelled');
}
```

When the native side returns `PlatformException(code: 'payment_cancelled')`,
the generated client raises `PaymentCancelledException` — not a generic
`PlatformException`.

Full runnable sample: [`examples/payment_sdk_wrapper`](https://github.com/Anu-Code07/flutter-native-bridge/tree/main/examples/payment_sdk_wrapper).

## Example 2 — BLE / device telemetry (event streams)

```dart
@Bridge(channel: 'myapp/ble', version: 1)
abstract class BleBridge {
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});
  Future<void> connect(String peripheralId);

  @BridgeEvent(name: 'scanResults', bufferSize: 256)
  Stream<BleDevice> scanResults();

  @BridgeEvent(name: 'connectionState', replay: 1)
  Stream<BleConnectionState> connectionState();
}
```

`replay` and `bufferSize` are enforced by the runtime — late subscribers see
the last `replay` events without re-listening to the native side.

## Example 3 — On-device image processing (FFI)

```dart
@FFIBridge(
  library: 'my_image_processor',
  symbolPrefix: 'nf_img_',
  threading: FFIThreading.isolate,
)
abstract class ImageProcessorBridge {
  Uint8List blur(Uint8List image, {double radius = 8});
  Uint8List enhance(Uint8List image);
}
```

The generated client gives you a typed `Map<String, ImageProcessorBridgeFfiHandler>`
dispatch surface plus an `IsolateNativeExecutor` so your symbols never run on
the UI isolate.

Full sample: [`examples/ai_image_processor`](https://github.com/Anu-Code07/flutter-native-bridge/tree/main/examples/ai_image_processor).

## Example 4 — KYC / document capture (multi-step native UI)

```dart
@Bridge(channel: 'myapp/kyc', version: 1)
abstract class KycBridge {
  Future<KycSession> startSession(String userId);
  Future<KycResult> submitDocument(KycDocumentType type);

  @BridgeEvent(name: 'stepChanged', replay: 1)
  Stream<KycStep> stepChanged();

  Future<void> cancelSession();
}
```

Full sample: [`examples/kyc_document_capture`](https://github.com/Anu-Code07/flutter-native-bridge/tree/main/examples/kyc_document_capture).

## Imports

```dart
// Recommended — app and feature code
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

// Optional — same package, smaller surface
import 'package:nativeflow_bridge/annotations.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/runtime.dart';
import 'package:nativeflow_bridge/ffi.dart';
import 'package:nativeflow_bridge/devtools.dart';
```

Use `BridgeAnnotationCodec` / `BridgeAnnotationTransport` when the umbrella
import hides annotation enums.

## Package examples

```bash
dart run example/example.dart
dart run example/payment_bridge_example.dart
dart run example/ffi_bridge_example.dart
```

See [`example/README.md`](example/README.md) for a use-case index.

## Security

NativeFlow Bridge treats the Dart ↔ native boundary as a trust boundary by
default. Stack traces and raw error classes are not surfaced in release
builds, payload previews are opt-in and redacted, and ProGuard rules are
shipped for the Android plugin. See
[SECURITY.md](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/SECURITY.md).

## More documentation

- [Architecture](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/architecture.md)
- [Code generation](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/code_generation.md)
- [FFI](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/ffi.md)
- [DevTools](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/devtools.md)
- [Examples guide](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/examples.md)
- [Security](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/SECURITY.md)
