# Examples

NativeFlow Bridge examples for pub.dev and the monorepo. Start with the
patterns below, then open the linked projects for generated clients.

## Use-case index

| Scenario | Bridge type | Example |
|----------|-------------|---------|
| Payment / checkout SDK | `@Bridge` + `@BridgeEvent` | [Payment](#payment-sdk) |
| BLE, GPS, or device telemetry | `@Bridge` + streams | [BLE](#ble--device-telemetry) |
| On-device image / ML (C++) | `@FFIBridge` | [FFI](#ffi-image-processing) |
| KYC / document camera flow | `@Bridge` + streams | [KYC](#kyc--document-capture) |

## Payment SDK

Wrap a native payment provider. Flutter calls typed methods; native pushes status events.

```dart
@Bridge(channel: 'myapp/payments', version: 1)
abstract class PaymentBridge {
  Future<PaymentResult> pay(PaymentRequest request);
  @BridgeEvent(name: 'events') Stream<PaymentEvent> events();
  Future<void> cancelPayment();
}
```

- Package sample: `packages/nativeflow_bridge/example/payment_bridge_example.dart`
- Full project: [`examples/payment_sdk_wrapper`](../examples/payment_sdk_wrapper)

## BLE / device telemetry

Native SDK owns radio/hardware; Flutter subscribes to streams.

```dart
@Bridge(channel: 'myapp/ble', version: 1)
abstract class BleBridge {
  Future<void> connect(String id);
  @BridgeEvent(name: 'telemetry') Stream<DeviceTelemetry> telemetry();
}
```

- Package sample: `packages/nativeflow_bridge/example/ble_bridge_example.dart`

## FFI image processing

Call into a compiled native library on a background isolate.

```dart
@FFIBridge(library: 'my_image_processor', symbolPrefix: 'nf_img_')
abstract class ImageProcessorBridge {
  Uint8List blur(Uint8List image);
}
```

- Package sample: `packages/nativeflow_bridge/example/ffi_bridge_example.dart`
- Full project: [`examples/ai_image_processor`](../examples/ai_image_processor)

## KYC / document capture

Multi-step native UI with progress events back to Flutter.

```dart
@Bridge(channel: 'myapp/kyc', version: 1)
abstract class KycBridge {
  Future<KycResult> start(String userId);
  @BridgeEvent(name: 'step') Stream<KycStep> step();
}
```

Implement `KycBridgeNativeBridge` in Kotlin/Swift using strings from your generated `.g.dart` file.

## Workflow in every example

1. Add `nativeflow_bridge` and `build_runner` to `pubspec.yaml`.
2. Define an `abstract class` with `@Bridge` or `@FFIBridge`.
3. Run `dart run build_runner build --delete-conflicting-outputs`.
4. Use `_$YourBridgeClient()` from a repository or use case.
5. Implement the generated native contract on Android/iOS (or FFI symbols on desktop/mobile).

See [code_generation.md](code_generation.md) for generator details.
