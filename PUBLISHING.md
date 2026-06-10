# Publishing

NativeFlow Bridge publishes **one package** to pub.dev: `nativeflow_bridge`.

All SDK code (annotations, core, generator, runtime, FFI, DevTools, and native
platform plugins) lives in `packages/nativeflow_bridge/`. The other folders
under `packages/bridge_*` are monorepo-only compatibility shims
(`publish_to: none`).

## Dry run

Supports Flutter **3.44+** (Dart **3.7+**).

```bash
dart pub global activate melos
flutter pub get
melos run analyze
melos run test:flutter
dart pub -C packages/nativeflow_bridge publish --dry-run
```

## Consumer imports

**Recommended** — single umbrella import:

```dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';
```

**Optional** — granular imports from the same package (no extra pub deps):

```dart
import 'package:nativeflow_bridge/annotations.dart';
import 'package:nativeflow_bridge/core.dart';
import 'package:nativeflow_bridge/runtime.dart';
import 'package:nativeflow_bridge/ffi.dart';
import 'package:nativeflow_bridge/devtools.dart';
```

Code generation in your app:

```yaml
dev_dependencies:
  build_runner: ^2.4.15
  nativeflow_bridge: ^1.0.0
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Release

1. Bump `packages/nativeflow_bridge/pubspec.yaml` `version:` and update
   `CHANGELOG.md`.
2. Commit + push.
3. Tag the release: `git tag v1.0.0 && git push origin v1.0.0`.
4. The `Release` GitHub Action runs `dart pub publish --force` via
   OIDC-trusted credentials and creates a GitHub Release.

Manual publish (fallback):

```bash
dart pub -C packages/nativeflow_bridge publish
```

There is no multi-package publish order.
