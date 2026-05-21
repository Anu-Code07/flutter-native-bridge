/// Single public entrypoint for the NativeFlow Bridge SDK.
library nativeflow_bridge;

import 'package:nativeflow_bridge/annotations.dart' as annotations;

export 'package:nativeflow_bridge/annotations.dart'
    hide BridgeCodec, BridgeTransport;
export 'package:nativeflow_bridge/core.dart';
export 'package:nativeflow_bridge/devtools.dart';
export 'package:nativeflow_bridge/ffi.dart';
export 'package:nativeflow_bridge/runtime.dart';

/// Annotation-only codec enum alias.
///
/// The core runtime also exposes a `BridgeCodec` interface, so annotation codec
/// options are available through this alias from the umbrella import.
typedef BridgeAnnotationCodec = annotations.BridgeCodec;

/// Annotation-only transport enum alias.
///
/// The core runtime also exposes a `BridgeTransport` enum, so annotation
/// transport options are available through this alias from the umbrella import.
typedef BridgeAnnotationTransport = annotations.BridgeTransport;
