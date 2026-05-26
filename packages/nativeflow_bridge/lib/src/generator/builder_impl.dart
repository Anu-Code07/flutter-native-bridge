import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'bridge_generator.dart';

Builder nativeflowBridgeBuilder(BuilderOptions options) {
  return SharedPartBuilder(<Generator>[
    BridgeContractGenerator(),
  ], 'nativeflow_bridge');
}
