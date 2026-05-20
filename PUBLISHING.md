# Publishing

NativeFlow Bridge is a pub workspace with a single public umbrella package:
`nativeflow_bridge`. Publish packages from their package directories, not from
the workspace root.

Run a dry run before publishing the public package:

```bash
dart pub -C packages/nativeflow_bridge publish --dry-run
```

The umbrella package exposes one import for consumers:

```dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';
```

The internal workspace packages remain publishable implementation packages. Run
dry runs for them only when publishing or validating those package boundaries:

```bash
dart pub -C packages/bridge_annotations publish --dry-run
dart pub -C packages/bridge_core publish --dry-run
dart pub -C packages/bridge_generator publish --dry-run
dart pub -C packages/bridge_runtime publish --dry-run
dart pub -C packages/bridge_android publish --dry-run
dart pub -C packages/bridge_ios publish --dry-run
dart pub -C packages/bridge_macos publish --dry-run
dart pub -C packages/bridge_windows publish --dry-run
dart pub -C packages/bridge_linux publish --dry-run
dart pub -C packages/bridge_ffi publish --dry-run
dart pub -C packages/bridge_devtools publish --dry-run
```

If publishing every workspace package, publish them in dependency order:

1. `nativeflow_bridge_annotations`
2. `nativeflow_bridge_core`
3. `nativeflow_bridge_generator`
4. `nativeflow_bridge_runtime`
5. `nativeflow_bridge_ffi`
6. `nativeflow_bridge_android`
7. `nativeflow_bridge_ios`
8. `nativeflow_bridge_macos`
9. `nativeflow_bridge_windows`
10. `nativeflow_bridge_linux`
11. `nativeflow_bridge_devtools`
12. `nativeflow_bridge`

Author attribution is Anurag in the public package metadata, license, package
READMEs, and CocoaPods metadata.
