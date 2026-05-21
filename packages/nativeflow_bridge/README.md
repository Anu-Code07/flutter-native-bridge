# NativeFlow Bridge

Type-safe Flutter ↔ native bridges. Replace hand-written `MethodChannel` and
`EventChannel` boilerplate with annotated APIs, `build_runner` codegen, and a
shared runtime for Android, iOS, macOS, Windows, and Linux.

**Supports Flutter 3.27+** (Dart 3.6+). **Recommended:** Flutter **3.44+** (Dart 3.12+) for the newest `analyzer` and dependency scores on pub.dev.

| Flutter | Dart | `analyzer` resolved |
|---------|------|---------------------|
| 3.27 – 3.43 | 3.6 – 3.11 | 10.0.1 (Flutter `meta` 1.16 pin) |
| 3.44+ | 3.12+ | 13.x (latest) |

## What you solve

| Without NativeFlow Bridge | With NativeFlow Bridge |
|-------------------------|------------------------|
| String method names and `Map` arguments | Typed `Future` / `Stream` on a Dart interface |
| Separate EventChannel setup per feature | `@BridgeEvent` on the same contract |
| Dart, Kotlin, and Swift drift apart | Generated **Kotlin/Swift contracts** from one `@Bridge` |
| Channel glue scattered in UI/widgets | Generated client → repository/BLoC → native SDK |

## When to use it

- Wrapping a **payment, KYC, maps, or device SDK** that only ships native Android/iOS libraries
- **Brownfield** apps: existing Kotlin/Swift modules called from Flutter
- **Many methods + live events** (payment status, downloads, BLE, GPS feeds)
- **FFI** for C/C++/Rust (image processing, on-device ML, crypto)

Not a fit for a single trivial `invokeMethod` or pure Dart/HTTP features.

## Install

```yaml
dependencies:
  nativeflow_bridge: ^0.1.0

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

  @BridgeEvent(name: 'telemetry')
  Stream<DeviceTelemetry> telemetry();
}
```

**2. Generate** → `device_bridge.g.dart` contains `_$DeviceBridgeClient`, `BridgeDescriptor`, and native contract strings.

**3. Call from your app** (repository, not widgets):

```dart
final device = _$DeviceBridgeClient();
await device.connect('ble:abc');
device.telemetry().listen((t) => /* update state */);
```

**4. Implement native** using the generated Kotlin/Swift interface (copy from `.g.dart` into your Android/iOS project).

---

## Example 1 — Payment SDK (platform channels)

Wrap Razorpay, Stripe Terminal, or a bank SDK. Methods for actions, streams for status.

```dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'payment_bridge.g.dart';

@Bridge(channel: 'myapp/payments', version: 1)
abstract class PaymentBridge {
  Future<PaymentResult> pay(PaymentRequest request);

  @BridgeEvent(name: 'events', replay: 1, bufferSize: 64)
  Stream<PaymentEvent> events();

  Future<void> cancelPayment();
}

final class PaymentRequest {
  const PaymentRequest({
    required this.amountMinor,
    required this.currency,
    required this.orderId,
  });

  final int amountMinor;
  final String currency;
  final String orderId;

  Map<String, Object?> toJson() => {
        'amountMinor': amountMinor,
        'currency': currency,
        'orderId': orderId,
      };
}

@BridgeError('payment_cancelled')
final class PaymentCancelledException extends BridgeException {
  const PaymentCancelledException()
      : super('Payment cancelled.', code: 'payment_cancelled');
}
```

**Generated client usage:**

```dart
final bridge = _$PaymentBridgeClient();

final subscription = bridge.events().listen((event) {
  // authorized, failed, cancelled...
});

try {
  final result = await bridge.pay(
    PaymentRequest(amountMinor: 1999, currency: 'INR', orderId: 'ord_1'),
  );
} on BridgePlatformException catch (e) {
  if (e.code == 'payment_cancelled') throw const PaymentCancelledException();
} finally {
  await subscription.cancel();
}
```

**Generated Kotlin contract** (implement in Android, then call your SDK):

```kotlin
interface PaymentBridgeNativeBridge {
  suspend fun pay(request: Map<String, Any?>): Map<String, Any?>
  suspend fun cancelPayment(): Unit
  fun events(): Flow<Map<String, Any?>>
}
```

Full runnable sample: [repository `examples/payment_sdk_wrapper`](https://github.com/Anu-Code07/flutter-native-bridge/tree/main/examples/payment_sdk_wrapper).

---

## Example 2 — BLE / device telemetry (event streams)

Sensors and peripherals push ongoing data. Use `@BridgeEvent` instead of polling.

```dart
@Bridge(channel: 'myapp/ble', version: 1)
abstract class BleBridge {
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});
  Future<void> connect(String peripheralId);

  @BridgeEvent(name: 'scanResults')
  Stream<BleDevice> scanResults();

  @BridgeEvent(name: 'connectionState')
  Stream<BleConnectionState> connectionState();
}
```

**Solves:** one channel namespace, consistent event names (`myapp/ble/events/scanResults`), typed `Stream` in Dart.

---

## Example 3 — On-device image processing (FFI)

CPU-heavy work in a native `.so` / `.dylib` / `.dll` — no platform channel per pixel.

```dart
import 'dart:typed_data';
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'image_processor_bridge.g.dart';

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

**Solves:** structured FFI contract + isolate-friendly execution instead of ad-hoc `dart:ffi` lookups.

Full sample: [repository `examples/ai_image_processor`](https://github.com/Anu-Code07/flutter-native-bridge/tree/main/examples/ai_image_processor).

---

## Example 4 — KYC / document capture (multi-step native UI)

Native SDK owns the camera UI; Flutter only starts flow and reads result.

```dart
@Bridge(channel: 'myapp/kyc', version: 1)
abstract class KycBridge {
  Future<KycSession> startSession(String userId);
  Future<KycResult> submitDocument(KycDocumentType type);

  @BridgeEvent(name: 'stepChanged')
  Stream<KycStep> stepChanged();
}
```

**Solves:** Flutter stays thin; native team owns SDK screens; contract documents every step and event.

---

## Imports

```dart
// Recommended — app and feature code
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

// Optional — same package, smaller surface
import 'package:nativeflow_bridge/annotations.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/runtime.dart';
import 'package:nativeflow_bridge/ffi.dart';
```

Use `BridgeAnnotationCodec` / `BridgeAnnotationTransport` when the umbrella import hides annotation enums.

## Package examples

```bash
# From this package directory
dart run example/example.dart
dart run example/payment_bridge_example.dart
dart run example/ffi_bridge_example.dart
```

See [`example/README.md`](example/README.md) for a use-case index.

## Architecture (recommended)

```text
Widget → BLoC/Cubit → UseCase → _$YourBridgeClient → BridgeClient → Platform channel / FFI
                                      ↑
                               generated from @Bridge
```

Do not call `MethodChannel` directly from widgets.

## Status (0.1.0 — experimental)

APIs and generated contracts may change before 1.0.0. Native **file** codegen (writing Kotlin/Swift into `android/` / `ios/`) is on the [roadmap](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/roadmap.md); today contracts are emitted as strings inside `.g.dart`.

## More documentation

- [Architecture](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/architecture.md)
- [Code generation](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/code_generation.md)
- [FFI](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/ffi.md)
- [Examples guide](https://github.com/Anu-Code07/flutter-native-bridge/blob/main/docs/examples.md)
