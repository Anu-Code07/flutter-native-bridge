import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Operation that crosses the Flutter/native boundary.
enum BridgeOperationKind { method, event, message, ffi }

/// Lifecycle phase of a bridge operation.
enum BridgeOperationStatus { started, success, error, timeout, cancelled }

/// One observable record of a bridge call, message, or event delivery.
///
/// Records are intentionally metadata-first: payloads are summarised by size
/// only unless the application opts into raw payload inspection.
@immutable
final class BridgeTimelineEvent {
  const BridgeTimelineEvent({
    required this.id,
    required this.bridge,
    required this.channel,
    required this.operation,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.requestBytes,
    this.responseBytes,
    this.errorCode,
    this.errorMessage,
    this.transport,
    this.requestPreview,
    this.responsePreview,
  });

  /// Monotonically increasing identifier within a process.
  final int id;
  final String bridge;
  final String channel;
  final String operation;
  final BridgeOperationKind kind;
  final BridgeOperationStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? requestBytes;
  final int? responseBytes;
  final String? errorCode;
  final String? errorMessage;
  final String? transport;

  /// Optional redacted request payload, only populated when the application
  /// has explicitly enabled payload inspection.
  final Object? requestPreview;

  /// Optional redacted response payload, only populated when the application
  /// has explicitly enabled payload inspection.
  final Object? responsePreview;

  Duration? get duration {
    final completedAt = this.completedAt;
    if (completedAt == null) {
      return null;
    }
    return completedAt.difference(startedAt);
  }

  BridgeTimelineEvent copyWith({
    BridgeOperationStatus? status,
    DateTime? completedAt,
    int? responseBytes,
    String? errorCode,
    String? errorMessage,
    Object? responsePreview,
  }) {
    return BridgeTimelineEvent(
      id: id,
      bridge: bridge,
      channel: channel,
      operation: operation,
      kind: kind,
      status: status ?? this.status,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      requestBytes: requestBytes,
      responseBytes: responseBytes ?? this.responseBytes,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      transport: transport,
      requestPreview: requestPreview,
      responsePreview: responsePreview ?? this.responsePreview,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'bridge': bridge,
    'channel': channel,
    'operation': operation,
    'kind': kind.name,
    'status': status.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'durationMicros': duration?.inMicroseconds,
    'requestBytes': requestBytes,
    'responseBytes': responseBytes,
    'errorCode': errorCode,
    'errorMessage': errorMessage,
    'transport': transport,
    if (requestPreview != null) 'requestPreview': requestPreview,
    if (responsePreview != null) 'responsePreview': responsePreview,
  };
}

/// Bounded in-memory ring buffer of recent [BridgeTimelineEvent]s.
final class BridgeTimeline {
  BridgeTimeline({this.capacity = 500});

  final int capacity;
  final List<BridgeTimelineEvent> _events = <BridgeTimelineEvent>[];

  List<BridgeTimelineEvent> get events =>
      List<BridgeTimelineEvent>.unmodifiable(_events);

  void record(BridgeTimelineEvent event) {
    _events.add(event);
    if (_events.length > capacity) {
      _events.removeRange(0, _events.length - capacity);
    }
  }

  /// Replaces a prior `started` event with its terminal counterpart.
  void update(BridgeTimelineEvent event) {
    final index = _events.indexWhere((existing) => existing.id == event.id);
    if (index == -1) {
      record(event);
      return;
    }
    _events[index] = event;
  }

  void clear() {
    _events.clear();
  }
}

/// Latency / throughput counters maintained per channel + operation.
@immutable
final class BridgeOperationStats {
  const BridgeOperationStats({
    required this.bridge,
    required this.channel,
    required this.operation,
    required this.kind,
    required this.totalCalls,
    required this.errorCount,
    required this.timeoutCount,
    required this.minMicros,
    required this.maxMicros,
    required this.totalMicros,
  });

  final String bridge;
  final String channel;
  final String operation;
  final BridgeOperationKind kind;
  final int totalCalls;
  final int errorCount;
  final int timeoutCount;
  final int minMicros;
  final int maxMicros;
  final int totalMicros;

  double get averageMicros => totalCalls == 0 ? 0 : totalMicros / totalCalls;

  double get errorRate => totalCalls == 0 ? 0 : errorCount / totalCalls;

  Map<String, Object?> toJson() => <String, Object?>{
    'bridge': bridge,
    'channel': channel,
    'operation': operation,
    'kind': kind.name,
    'totalCalls': totalCalls,
    'errorCount': errorCount,
    'timeoutCount': timeoutCount,
    'minMicros': minMicros,
    'maxMicros': maxMicros,
    'averageMicros': averageMicros,
    'errorRate': errorRate,
  };
}

/// Aggregates [BridgeTimelineEvent]s into per-operation statistics.
final class BridgeStatsAggregator {
  final Map<String, _MutableStats> _bucket = <String, _MutableStats>{};

  List<BridgeOperationStats> snapshot() {
    return _bucket.values.map((stats) => stats.toImmutable()).toList()
      ..sort((a, b) => b.totalCalls.compareTo(a.totalCalls));
  }

  void observe(BridgeTimelineEvent event) {
    if (event.status == BridgeOperationStatus.started) {
      return;
    }
    final key = '${event.channel}::${event.operation}';
    final stats = _bucket.putIfAbsent(
      key,
      () => _MutableStats(
        bridge: event.bridge,
        channel: event.channel,
        operation: event.operation,
        kind: event.kind,
      ),
    );
    stats.observe(event);
  }

  void clear() => _bucket.clear();
}

class _MutableStats {
  _MutableStats({
    required this.bridge,
    required this.channel,
    required this.operation,
    required this.kind,
  });

  final String bridge;
  final String channel;
  final String operation;
  final BridgeOperationKind kind;
  int totalCalls = 0;
  int errorCount = 0;
  int timeoutCount = 0;
  int minMicros = 0;
  int maxMicros = 0;
  int totalMicros = 0;

  void observe(BridgeTimelineEvent event) {
    totalCalls += 1;
    if (event.status == BridgeOperationStatus.error) {
      errorCount += 1;
    }
    if (event.status == BridgeOperationStatus.timeout) {
      timeoutCount += 1;
      errorCount += 1;
    }
    final micros = event.duration?.inMicroseconds;
    if (micros != null) {
      if (totalCalls == 1 || micros < minMicros) {
        minMicros = micros;
      }
      if (micros > maxMicros) {
        maxMicros = micros;
      }
      totalMicros += micros;
    }
  }

  BridgeOperationStats toImmutable() => BridgeOperationStats(
    bridge: bridge,
    channel: channel,
    operation: operation,
    kind: kind,
    totalCalls: totalCalls,
    errorCount: errorCount,
    timeoutCount: timeoutCount,
    minMicros: minMicros,
    maxMicros: maxMicros,
    totalMicros: totalMicros,
  );
}

/// Singleton observer used by [BridgeClient] to publish bridge activity.
///
/// `BridgeInspector` is intentionally lightweight: it records metadata,
/// notifies listeners, optionally forwards events to the VM service
/// (so Dart DevTools sees them natively), and never holds raw payloads
/// unless the application opts in.
final class BridgeInspector {
  BridgeInspector._({this.capacity = 500})
    : _timeline = BridgeTimeline(capacity: capacity);

  /// Shared inspector used by [BridgeClient] when no custom inspector is
  /// injected.
  static final BridgeInspector instance = BridgeInspector._();

  /// Maximum events retained in the in-memory ring buffer.
  final int capacity;

  final BridgeTimeline _timeline;
  final BridgeStatsAggregator _stats = BridgeStatsAggregator();
  final StreamController<BridgeTimelineEvent> _controller =
      StreamController<BridgeTimelineEvent>.broadcast();

  int _idSequence = 0;
  bool _enabled = !kReleaseMode;
  bool _capturePayloads = false;
  bool _vmServiceBroadcast = !kReleaseMode;

  /// Whether the inspector is recording events.
  bool get isEnabled => _enabled;

  set isEnabled(bool value) => _enabled = value;

  /// Whether to capture (redacted) request/response payload previews.
  ///
  /// Off by default — payloads stay on-device and out of DevTools telemetry
  /// unless the application explicitly enables it.
  bool get capturePayloads => _capturePayloads;

  set capturePayloads(bool value) => _capturePayloads = value;

  /// Whether to forward each event to `dart:developer` so Dart DevTools and
  /// the NativeFlow Bridge DevTools extension can stream them live.
  bool get vmServiceBroadcast => _vmServiceBroadcast;

  set vmServiceBroadcast(bool value) => _vmServiceBroadcast = value;

  /// Live broadcast of timeline events.
  Stream<BridgeTimelineEvent> get events => _controller.stream;

  /// Snapshot of recent events.
  List<BridgeTimelineEvent> get timeline => _timeline.events;

  /// Snapshot of aggregated per-operation statistics.
  List<BridgeOperationStats> get stats => _stats.snapshot();

  /// Mints a new event id used to correlate started/completed records.
  int nextId() => ++_idSequence;

  /// Records a new event or updates an existing one (same `id`).
  void record(BridgeTimelineEvent event) {
    if (!_enabled) {
      return;
    }
    if (event.status == BridgeOperationStatus.started) {
      _timeline.record(event);
    } else {
      _timeline.update(event);
      _stats.observe(event);
    }
    _broadcast(event);
  }

  void _broadcast(BridgeTimelineEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
    if (_vmServiceBroadcast) {
      try {
        developer.postEvent('nativeflow_bridge.timeline', event.toJson());
      } on Object {
        // Best-effort only; never let DevTools telemetry break a bridge call.
      }
    }
  }

  /// Exports the current timeline + stats as a HAR-like JSON document.
  Map<String, Object?> export() => <String, Object?>{
    'version': 1,
    'capacity': capacity,
    'enabled': _enabled,
    'capturePayloads': _capturePayloads,
    'events': _timeline.events.map((event) => event.toJson()).toList(),
    'stats': _stats.snapshot().map((stats) => stats.toJson()).toList(),
  };

  /// Convenience for `jsonEncode(export())`.
  String exportJson() => jsonEncode(export());

  void clear() {
    _timeline.clear();
    _stats.clear();
  }

  Future<void> close() async {
    await _controller.close();
  }
}

/// Approximate, allocation-free size estimation for telemetry only.
int estimatePayloadBytes(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is String) {
    return value.length;
  }
  if (value is List<int>) {
    return value.length;
  }
  try {
    return jsonEncode(value).length;
  } on Object {
    return value.toString().length;
  }
}
