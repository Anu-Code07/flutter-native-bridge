// FFI — blur/enhance images via a native .so / .dylib / .dll.
//
// Run: dart run example/ffi_bridge_example.dart
import 'dart:typed_data';

import 'package:nativeflow_bridge/nativeflow_bridge.dart';

@FFIBridge(
  library: 'my_image_processor',
  symbolPrefix: 'nf_img_',
  threading: FFIThreading.isolate,
)
abstract class ImageProcessorBridge {
  Uint8List blur(Uint8List image, {double radius = 8});
  Uint8List enhance(Uint8List image);
}

void main() {
  print('FFI bridge contract');
  print('  library: my_image_processor');
  print('  threading: ${FFIThreading.isolate}');
  print('  use for C/C++/Rust CPU work without platform channels');
}
