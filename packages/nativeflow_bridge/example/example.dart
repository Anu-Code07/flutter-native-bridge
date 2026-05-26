import 'package:nativeflow_bridge/nativeflow_bridge.dart';

/// Minimal example: define a typed bridge contract with annotations.
///
/// Run from the package directory:
/// `dart run example/example.dart`
///
/// In your app, run code generation with:
/// `dart run build_runner build --delete-conflicting-outputs`
@Bridge(channel: 'nativeflow/example', version: 1)
abstract class ExampleBridge {
  Future<String> greet(String name);

  @BridgeEvent(name: 'status')
  Stream<String> statusUpdates();
}

void main() {
  print('NativeFlow Bridge — minimal example');
  print('Channel: nativeflow/example');
  print('Codec: ${BridgeAnnotationCodec.json}');
  print('');
  print('More examples in this folder:');
  print('  payment_bridge_example.dart  — fintech / checkout SDK');
  print('  ble_bridge_example.dart      — device telemetry streams');
  print('  ffi_bridge_example.dart      — C/C++ native library');
  print('  inspector_example.dart       — DevTools inspector + redactor');
  print('');
  print('See example/README.md and package README on pub.dev.');
}
