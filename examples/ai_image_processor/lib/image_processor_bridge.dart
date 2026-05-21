import 'dart:typed_data';

import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'image_processor_bridge.g.dart';

@FFIBridge(
  library: 'nativeflow_image_processor',
  symbolPrefix: 'nf_image_',
  threading: FFIThreading.isolate,
)
abstract class ImageProcessorBridge {
  Uint8List blur(Uint8List image, {double radius = 8});

  Uint8List enhance(Uint8List image);
}
