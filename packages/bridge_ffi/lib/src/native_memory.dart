import 'dart:ffi';
import 'dart:typed_data';

/// Owns temporary native allocations for a single generated FFI call.
final class NativeMemoryScope {
  NativeMemoryScope(this._allocator);

  final Allocator _allocator;
  final List<Pointer<NativeType>> _allocations = <Pointer<NativeType>>[];

  Pointer<Uint8> bytes(Uint8List value) {
    final pointer = allocateBytes(value.length);
    pointer.asTypedList(value.length).setAll(0, value);
    return pointer;
  }

  Pointer<Uint8> allocateBytes(int count) {
    final pointer = _allocator<Uint8>(count);
    _allocations.add(pointer.cast<NativeType>());
    return pointer;
  }

  void release() {
    for (final pointer in _allocations.reversed) {
      _allocator.free(pointer);
    }
    _allocations.clear();
  }
}

/// Runs a block with deterministic native memory cleanup.
T usingNativeMemory<T>(Allocator allocator, T Function(NativeMemoryScope) run) {
  final scope = NativeMemoryScope(allocator);
  try {
    return run(scope);
  } finally {
    scope.release();
  }
}
