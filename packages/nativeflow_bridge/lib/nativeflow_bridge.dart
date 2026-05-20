/// Single public entrypoint for the NativeFlow Bridge SDK.
library nativeflow_bridge;

import 'package:nativeflow_bridge_annotations/bridge_annotations.dart'
    as annotations;

export 'package:nativeflow_bridge_android/bridge_android.dart';
export 'package:nativeflow_bridge_annotations/bridge_annotations.dart'
    hide BridgeCodec, BridgeTransport;
export 'package:nativeflow_bridge_core/bridge_core.dart';
export 'package:nativeflow_bridge_devtools/bridge_devtools.dart';
export 'package:nativeflow_bridge_ffi/bridge_ffi.dart';
export 'package:nativeflow_bridge_generator/bridge_generator.dart';
export 'package:nativeflow_bridge_ios/bridge_ios.dart';
export 'package:nativeflow_bridge_linux/bridge_linux.dart';
export 'package:nativeflow_bridge_macos/bridge_macos.dart';
export 'package:nativeflow_bridge_runtime/bridge_runtime.dart';
export 'package:nativeflow_bridge_windows/bridge_windows.dart';

/// Annotation-only codec enum alias.
///
/// The core runtime also exposes a `BridgeCodec` interface, so annotation codec
/// options are available through this alias from the umbrella package.
typedef BridgeAnnotationCodec = annotations.BridgeCodec;

/// Annotation-only transport enum alias.
///
/// The core runtime also exposes a `BridgeTransport` enum, so annotation
/// transport options are available through this alias from the umbrella package.
typedef BridgeAnnotationTransport = annotations.BridgeTransport;
