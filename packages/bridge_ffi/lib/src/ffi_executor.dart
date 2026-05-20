import 'dart:isolate';

/// Executes blocking native work away from the UI isolate.
abstract interface class NativeExecutor {
  Future<T> run<T>(T Function() operation);
}

/// Uses `Isolate.run` for CPU-heavy or blocking native calls.
final class IsolateNativeExecutor implements NativeExecutor {
  const IsolateNativeExecutor();

  @override
  Future<T> run<T>(T Function() operation) => Isolate.run(operation);
}

/// Executes immediately on the current isolate for cheap native calls.
final class InlineNativeExecutor implements NativeExecutor {
  const InlineNativeExecutor();

  @override
  Future<T> run<T>(T Function() operation) async => operation();
}
