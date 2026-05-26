# Roadmap

NativeFlow Bridge 1.0.0 is the first production release. This page tracks
work landing after 1.0.

## Runtime extensions

- Protobuf and binary codec packages (current codecs: identity, JSON).
- Native file emission into Android / iOS source sets (today contracts are
  emitted as strings inside `.g.dart`).
- Encrypted bridge transport for sensitive payloads.
- Hot-swappable bridge plugins for A/B and gradual rollout.

## DevTools

- Standalone NativeFlow Bridge DevTools extension (`devtools_extensions`)
  consuming the existing `ext.nativeflow_bridge.*` service extensions.
- Built-in CSV / HAR export.
- Per-bridge metrics dashboards.

## Native parity

- Generated handler stubs (Kotlin / Swift / C++ / C) automatically wired
  into platform source sets.
- AI-assisted native SDK wrapper generation for common SDKs.
- WASM and Rust-first bridge targets.

## Quality

- Coverage upload to Codecov on every CI run.
- Native build + smoke test on Android, iOS, macOS, Windows, Linux runners.
- Compatibility matrix tests for old Flutter releases.
