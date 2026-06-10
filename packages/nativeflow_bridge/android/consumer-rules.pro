# NativeFlow Bridge runtime is reached via reflection-free APIs only.
# Keep the public runtime surface so app-side generators can dispatch to it.
-keep class nativeflow.bridge.android.NativeFlowBridgeRuntime { *; }
-keep class nativeflow.bridge.android.NativeFlowBridgeError { *; }
-keep interface nativeflow.bridge.android.NativeFlowMethodHandler { *; }
-keep interface nativeflow.bridge.android.NativeFlowEventSource { *; }
-keep class nativeflow.bridge.android.NativeFlowBridgePlugin { *; }

# Kotlin coroutines names are used by the runtime CoroutineScope.
-keepclassmembers class kotlinx.coroutines.** { *; }
