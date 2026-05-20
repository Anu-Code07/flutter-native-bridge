/// Transport families supported by NativeFlow Bridge.
enum BridgeTransport {
  methodChannel,
  eventChannel,
  basicMessageChannel,
  ffi,
}

/// Execution policy for asynchronous native work.
enum BridgeExecutionPolicy {
  mainThread,
  backgroundThread,
  isolate,
}
