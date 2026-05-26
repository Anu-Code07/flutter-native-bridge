package nativeflow.bridge.android

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

interface NativeFlowMethodHandler {
  suspend fun handle(method: String, arguments: Any?): Any?
}

interface NativeFlowEventSource {
  fun onListen(arguments: Any?, sink: EventChannel.EventSink)
  fun onCancel(arguments: Any?)
}

/**
 * Typed bridge error raised from native handlers. Maps to `@BridgeError`
 * exceptions on the Dart side via [PlatformException.code].
 */
class NativeFlowBridgeError(
  val code: String,
  message: String,
  val details: Any? = null,
) : RuntimeException(message)

class NativeFlowBridgeRuntime(
  private val messenger: BinaryMessenger,
) {
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
  private val methodChannels = mutableMapOf<String, MethodChannel>()
  private val eventChannels = mutableMapOf<String, EventChannel>()

  /**
   * When `false` (the default in release builds) the runtime omits native
   * stack traces and raw exception classes from cross-boundary error details
   * for security and privacy.
   */
  var emitDebugErrorDetails: Boolean = BuildFlags.isDebug

  fun registerMethods(channelName: String, handler: NativeFlowMethodHandler) {
    val channel = MethodChannel(messenger, channelName)
    channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
      scope.launch {
        try {
          result.success(handler.handle(call.method, call.arguments))
        } catch (bridgeError: NativeFlowBridgeError) {
          result.error(
            bridgeError.code,
            bridgeError.message ?: "Native bridge call failed.",
            if (emitDebugErrorDetails) bridgeError.details else null,
          )
        } catch (error: Throwable) {
          result.error(
            error::class.java.simpleName,
            error.message ?: "Native bridge call failed.",
            if (emitDebugErrorDetails) {
              mapOf("stackTrace" to error.stackTraceToString())
            } else {
              null
            },
          )
        }
      }
    }
    methodChannels[channelName] = channel
  }

  fun registerEvents(channelName: String, source: NativeFlowEventSource) {
    val channel = EventChannel(messenger, channelName)
    channel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        source.onListen(arguments, events)
      }

      override fun onCancel(arguments: Any?) {
        source.onCancel(arguments)
      }
    })
    eventChannels[channelName] = channel
  }

  fun dispose() {
    methodChannels.values.forEach { it.setMethodCallHandler(null) }
    eventChannels.values.forEach { it.setStreamHandler(null) }
    methodChannels.clear()
    eventChannels.clear()
    scope.cancel()
  }
}
