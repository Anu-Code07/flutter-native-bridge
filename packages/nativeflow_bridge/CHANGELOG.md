# Changelog

## 1.0.0

NativeFlow Bridge **1.0.0** — first production release.

### New

- **`BridgeInspector`** — in-process recorder for every method, message, event,
  and error crossing the bridge. Bounded ring buffer (default 500), per-event
  broadcast stream, JSON export, and per-operation latency / error / timeout
  stats.
- **`BridgeInspectorPanel`** — drop-in Flutter widget for live, in-app bridge
  introspection (timeline, stats, error feed, payload previews).
- **`BridgeDevToolsService`** — registers `ext.nativeflow_bridge.*`
  VM-service extensions consumed by Dart DevTools and the optional NativeFlow
  Bridge DevTools extension; each event is also published via
  `developer.postEvent('nativeflow_bridge.timeline', …)`.
- **`BridgePayloadRedactor`** — opt-in payload preview redaction for tokens,
  PANs, CVVs, sessions, cookies, and similar fields.
- Annotation surface is now fully wired: `@Bridge(codec, platforms)`,
  `@BridgeMethod(transport, timeout)`, `@BridgeEvent(replay, bufferSize)`,
  `@BridgeError(code)` flow through the generator into the runtime descriptor
  and a per-client `BridgeErrorMapper`.
- `BridgeEventStreamRegistry` does lifecycle-aware **auto-reconnect** with
  bounded replay buffers.
- **macOS** runtime now matches **iOS** feature parity (events, async, typed
  `NativeFlowBridgeError`).
- **Windows** and **Linux** plugins ship a real `NativeFlowBridgeRuntime` with
  method + event channel registration helpers.
- Android plugin ships `consumer-rules.pro`, JVM 1.8 target, and an explicit
  `kotlinx-coroutines-android` dependency.
- Native contract emitters now cover **Kotlin, Swift, Windows C++, and Linux C**
  and surface `@BridgeError` codes as native constants.
- **FFI** generator emits a typed client with a `Map<String, …FfiHandler>`
  dispatch surface (no longer metadata-only).
- New end-to-end **KYC document capture** example.

### Security

- Stack traces are no longer leaked across the Flutter boundary in release
  builds. Android / iOS / macOS runtimes only include error `details` when
  `emitDebugErrorDetails = true`, defaulting to `false` outside debug builds.
- DevTools telemetry is metadata-first; raw payloads are opt-in and pass
  through the redactor.
- New `SECURITY.md` and vulnerability-reporting policy.

### Breaking

- `BridgeTransport` and related enums moved to `package:nativeflow_bridge/core.dart`
  with an additional `BridgeCodecKind` and `BridgePlatformTarget`. Public
  `BridgeTimeline` API is replaced by `BridgeInspector` + `BridgeTimelineEvent`
  (the timeline class still exists as the underlying ring buffer).
- `BridgeMethodDescriptor` gained `transport`; `BridgeEventDescriptor` gained
  `replay` / `bufferSize`; `BridgeDescriptor` gained `codec`, `platforms`,
  `errors`.
- Generated client constructors now accept an optional `BridgeSerializerRegistry`
  and build their own `BridgeErrorMapper`.

## 0.1.0

- Experimental first pub.dev release.
- Single public NativeFlow Bridge package entrypoint.
- Annotations, core descriptors, runtime channel APIs, FFI helpers,
  `build_runner` generator, and platform plugin shells.
- Documents experimental status.
