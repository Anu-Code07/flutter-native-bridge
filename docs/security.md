# Security model

NativeFlow Bridge treats every bridge contract as a trust boundary. Generated
and runtime code validates payload shape and gates diagnostic detail before
invoking native SDKs.

## Controls (enforced by default in 1.0)

- **No stack traces across the boundary in release builds.** Android, iOS,
  and macOS runtimes only set `details` when `emitDebugErrorDetails = true`,
  which defaults to `false` outside of debug builds.
- **Typed errors via `@BridgeError(code)`** — generators wire a
  `BridgeErrorMapper` that converts `PlatformException(code: …)` into the
  user's Dart exception, eliminating leaked native exception class names.
- **Metadata-first DevTools** — `BridgeInspector` captures sizes, durations,
  transports, and error codes by default. Raw payload previews are opt-in
  (`capturePayloads = true`) and pass through `BridgePayloadRedactor`.
- **Stable, versioned channels** — `BridgeRegistry` rejects duplicate
  channel registrations when the contract version differs.
- **Explicit codecs** — every `@Bridge` declares `codec:`; the generator
  emits the matching `BridgeCodec` instance instead of silently falling back
  to identity passthrough.
- **ProGuard / R8 rules** — the Android plugin ships `consumer-rules.pro`
  that keeps the public runtime surface.

## Sensitive payload guidance

For tokens, payment secrets, health data, NFC payloads, or model prompts:

1. Prefer opaque handles over raw values.
2. Keep permission prompts inside the native adapter closest to the OS.
3. Encrypt persisted native state via Keychain (iOS/macOS), Keystore
   (Android), or DPAPI (Windows).
4. Scope permissions to the bridge method that needs them.
5. Clear native buffers after FFI calls when the platform supports it.
6. Treat `BridgeInspectorPanel` as a debug-only surface. Guard it behind
   `kDebugMode` or a build flavour, and never enable `capturePayloads` in
   production builds.

## Vulnerability reporting

See [`SECURITY.md`](../SECURITY.md) at the repository root for the disclosure
policy, supported versions, and contact address.
