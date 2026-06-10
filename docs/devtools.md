# DevTools

NativeFlow Bridge ships a first-class DevTools experience so consumers can
introspect every method, message, event, and error crossing the Flutter ↔
native boundary in real time.

## Components

| Component | Purpose |
|-----------|---------|
| `BridgeInspector` | In-process recorder. Holds a bounded ring buffer of `BridgeTimelineEvent`s, computes per-operation stats, exposes a broadcast `Stream`, and forwards events via `developer.postEvent`. |
| `BridgeTimelineEvent` | One observable record: bridge, channel, operation, kind, status, timing, byte sizes, transport, optional redacted payload preview, error code/message. |
| `BridgeOperationStats` | Per-channel + operation aggregate: calls, errors, timeouts, min/max/avg µs, error rate. |
| `BridgeInspectorPanel` | Drop-in Flutter widget with timeline, stats, errors, and JSON export. |
| `BridgePayloadRedactor` | Structural redaction for tokens, PANs, CVVs, sessions, cookies, and similar. Used before any payload reaches DevTools. |
| `BridgeDevToolsService` | Registers `ext.nativeflow_bridge.*` VM-service extensions. |

## Wiring it up

```dart
import 'package:flutter/material.dart';
import 'package:nativeflow_bridge/devtools.dart';

void main() {
  BridgeDevToolsService.register();
  runApp(const MyApp());
}

class DebugDrawerEntry extends StatelessWidget {
  const DebugDrawerEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Bridge Inspector'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: BridgeInspectorPanel()),
        ),
      ),
    );
  }
}
```

## VM-service extensions

| Method | Description |
|--------|-------------|
| `ext.nativeflow_bridge.timeline` | Returns the full timeline + stats as JSON. |
| `ext.nativeflow_bridge.stats` | Returns only aggregated stats. |
| `ext.nativeflow_bridge.clear` | Clears the in-memory buffer. |
| `ext.nativeflow_bridge.config` | Reads / writes `enabled`, `capturePayloads`, `vmServiceBroadcast`. |

Every event is also published via
`developer.postEvent('nativeflow_bridge.timeline', event.toJson())`, so Dart
DevTools and any custom listener can subscribe live without polling.

## Privacy defaults

- `BridgeInspector.isEnabled` defaults to `!kReleaseMode`.
- `capturePayloads` defaults to `false`. When you enable it, every payload is
  walked by `BridgePayloadRedactor` first, which replaces values under
  sensitive keys with `[REDACTED]`.
- `vmServiceBroadcast` defaults to `!kReleaseMode`.
- The Android / iOS / macOS native runtimes also gate
  `emitDebugErrorDetails`, so production builds never push native stack
  traces across the boundary.

## Exporting traces

```dart
final json = BridgeInspector.instance.exportJson();
await Clipboard.setData(ClipboardData(text: json));
```

`BridgeInspectorPanel` exposes a one-click copy button that does the same.

## Extending it

Because `BridgeInspector.events` is a broadcast `Stream`, you can pipe the
data anywhere — analytics, structured logs, Crashlytics breadcrumbs, your
own observability stack — with no extra dependencies.

```dart
BridgeInspector.instance.events.listen((event) {
  if (event.status == BridgeOperationStatus.error) {
    crashlytics.log('${event.channel}:${event.operation} ${event.errorCode}');
  }
});
```
