package nativeflow.bridge.android

/**
 * Safe default for whether the runtime should surface debug-only error
 * details to the Flutter boundary. The host app is responsible for flipping
 * [NativeFlowBridgeRuntime.emitDebugErrorDetails] to `true` for development
 * builds; production builds keep stack traces and raw error classes off the
 * wire.
 */
internal object BuildFlags {
  const val isDebug: Boolean = false
}
