# NativeFlow Bridge — examples

Runnable snippets for pub.dev. Copy patterns into your app, then run
`build_runner` to generate `*.g.dart` clients.

| File | Use case |
|------|----------|
| [`example.dart`](example.dart) | Minimal `@Bridge` contract (methods + events) |
| [`payment_bridge_example.dart`](payment_bridge_example.dart) | Payment / fintech SDK wrapper |
| [`ble_bridge_example.dart`](ble_bridge_example.dart) | BLE / device telemetry streams |
| [`ffi_bridge_example.dart`](ffi_bridge_example.dart) | C/C++ image or ML library via `@FFIBridge` |
| [`inspector_example.dart`](inspector_example.dart) | In-process `BridgeInspector` + redactor + JSON export |

## Run

```bash
cd packages/nativeflow_bridge
dart run example/example.dart
dart run example/payment_bridge_example.dart
```

## Full projects in the monorepo

- [`examples/payment_sdk_wrapper`](../../examples/payment_sdk_wrapper) — generated client + models
- [`examples/ai_image_processor`](../../examples/ai_image_processor) — FFI bridge
- [`examples/kyc_document_capture`](../../examples/kyc_document_capture) — multi-step native flow
