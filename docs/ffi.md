# FFI guide

`nativeflow_bridge_ffi` provides low-level primitives for generated bindings:

- `NativeLibraryResolver` opens platform-specific dynamic libraries.
- `NativeLibrary.lookupPointer` resolves typed native symbols.
- `NativeMemoryScope` owns temporary allocations for one native call.
- `IsolateNativeExecutor` runs blocking native operations away from the UI
  isolate.

```dart
final library = NativeLibrary(name: 'nativeflow_image_processor');
final blurPointer = library.lookupPointer<
    NativeFunction<Pointer<Uint8> Function(Pointer<Uint8>, Int32)>>(
  'nf_image_blur',
);
final blur = blurPointer.asFunction<
    Pointer<Uint8> Function(Pointer<Uint8>, int)>();
```

## Memory ownership

Generated FFI code should make ownership explicit:

1. allocate request buffers in `NativeMemoryScope`
2. transfer only documented pointers to native code
3. copy native responses into Dart-managed `Uint8List`
4. free temporary allocations in `finally`

Native libraries that allocate response memory must expose a matching free
symbol. Generated bindings should call it after copying bytes into Dart memory.

## Async execution

CPU-heavy image, ML, compression, or crypto functions should use
`IsolateNativeExecutor`. Cheap pointer lookups and non-blocking calls can use
`InlineNativeExecutor`.
