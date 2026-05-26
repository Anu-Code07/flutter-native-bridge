/// DevTools telemetry primitives for NativeFlow Bridge.
///
/// Includes the in-process [BridgeInspector] that records bridge activity,
/// the drop-in [BridgeInspectorPanel] Flutter widget, payload redaction, and
/// service-extension registration consumed by Dart DevTools / the optional
/// NativeFlow Bridge DevTools extension.
library;

export 'src/devtools/bridge_devtools_service.dart';
export 'src/devtools/bridge_inspector_panel.dart';
export 'src/devtools/bridge_redactor.dart';
export 'src/devtools/bridge_timeline.dart';
