// BLE / device SDK — scan, connect, and telemetry over event streams.
//
// Run: dart run example/ble_bridge_example.dart
import 'package:nativeflow_bridge/nativeflow_bridge.dart';

@Bridge(channel: 'myapp/ble', version: 1)
abstract class BleBridge {
  Future<void> startScan();
  Future<void> connect(String peripheralId);
  Future<void> disconnect();

  @BridgeEvent(name: 'scanResults')
  Stream<String> scanResults();

  @BridgeEvent(name: 'connectionState')
  Stream<String> connectionState();
}

void main() {
  print('BLE bridge contract');
  print('  channel: myapp/ble');
  print('  use when a native BLE SDK exposes scan + connection callbacks');
  print('  Flutter listens to scanResults / connectionState streams');
}
