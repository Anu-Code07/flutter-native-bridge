# Security policy

We take security in the Flutter ↔ native boundary seriously. NativeFlow Bridge
treats every method, message, event, and FFI call crossing the boundary as a
trust boundary.

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a vulnerability

**Do not file a public issue for security vulnerabilities.**

Email a detailed report to **security@anu-code07.dev**. Please include:

1. A description of the issue and impact.
2. Reproduction steps or a minimal proof of concept.
3. The affected version of `nativeflow_bridge`.
4. Optional: suggested remediation.

You will receive an acknowledgement within 72 hours. A fix and coordinated
disclosure timeline will follow within 14 days for confirmed issues.

## Hardening guarantees

- **No raw payloads** are exported to DevTools by default. The
  `BridgeInspector` records metadata-first events (sizes, durations, codes).
  Payload previews are opt-in (`capturePayloads = true`) and pass through
  `BridgePayloadRedactor`, which strips common sensitive fields by default.
- **No native stack traces** cross the Flutter boundary in release builds.
  Android / iOS / macOS runtimes only emit `details` when
  `emitDebugErrorDetails = true`, which defaults to `false` outside of debug
  builds.
- **Typed errors** are mapped via `@BridgeError(code)` so application code
  catches structured Dart exceptions, not raw native exception classes.
- **ProGuard rules** are shipped (`consumer-rules.pro`) so the Android
  runtime survives R8 / minification.
- **Codecs** (`json`, `identity`, …) are explicit on each `@Bridge` and
  validated by the generator; consumers cannot accidentally fall back to
  unsafe identity passthrough.

## Defense in depth

When wrapping a sensitive native SDK (payments, KYC, BLE, NFC, ML):

1. Use opaque handles rather than raw payloads (PANs, tokens, biometrics).
2. Keep permission prompts inside the native handler closest to the OS.
3. Encrypt persisted native state via Keychain (iOS/macOS), Keystore
   (Android), or DPAPI (Windows).
4. Treat `BridgeInspectorPanel` as a debug-only surface. Guard it behind
   `kDebugMode` or a build flavour.
5. Clear native buffers after FFI calls when the platform supports it.

## Vulnerability classes we explicitly defend against

- Information leakage via cross-boundary error details (default-off in release).
- Confused-deputy bugs from generic `error.code` strings (typed `@BridgeError`).
- Replay or stale-state leakage from unbounded event streams (per-event
  `replay` / `bufferSize` caps).
- DevTools telemetry spills (metadata-first + redactor + opt-in raw payloads).
- Bridge version drift between Dart and native (`BridgeRegistry` rejects
  duplicate channels with mismatched versions).
