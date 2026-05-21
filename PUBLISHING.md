# Publishing

NativeFlow Bridge publishes **one package** to pub.dev: `nativeflow_bridge`.

All SDK code (annotations, core, generator, runtime, FFI, DevTools, and native
platform plugins) lives in `packages/nativeflow_bridge/`. The other folders under
`packages/bridge_*` are monorepo-only compatibility shims (`publish_to: none`).

## Dry run

Supports Flutter **3.27+** (Dart **3.6+**). Flutter **3.44+** recommended for latest tooling.

```bash
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
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
  nativeflow_bridge: ^0.1.0
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Publish

1. [Verify your publisher](https://pub.dev/help/publishing#publishing-your-package) on pub.dev.
2. Confirm checks above pass.
3. Publish only from the package directory:

```bash
dart pub -C packages/nativeflow_bridge publish
```

There is no multi-package publish order.
