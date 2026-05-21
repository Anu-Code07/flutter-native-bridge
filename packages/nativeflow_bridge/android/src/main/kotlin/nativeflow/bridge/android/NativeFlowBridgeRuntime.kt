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

class NativeFlowBridgeRuntime(
  private val messenger: BinaryMessenger,
) {
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
  private val methodChannels = mutableMapOf<String, MethodChannel>()
  private val eventChannels = mutableMapOf<String, EventChannel>()

  fun registerMethods(channelName: String, handler: NativeFlowMethodHandler) {
    val channel = MethodChannel(messenger, channelName)
    channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
      scope.launch {
        try {
          result.success(handler.handle(call.method, call.arguments))
        } catch (error: Throwable) {
          result.error(
            error::class.java.simpleName,
            error.message ?: "Native bridge call failed.",
            mapOf("stackTrace" to error.stackTraceToString()),
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
