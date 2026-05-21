import 'package:flutter/foundation.dart';

@immutable
final class BridgeTimelineEvent {
  const BridgeTimelineEvent({
    required this.bridge,
    required this.operation,
    required this.startedAt,
    this.completedAt,
    this.payloadBytes,
    this.errorCode,
  });

  final String bridge;
  final String operation;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? payloadBytes;
  final String? errorCode;

  Duration? get duration {
    final completedAt = this.completedAt;
    if (completedAt == null) {
      return null;
    }
    return completedAt.difference(startedAt);
  }
}

final class BridgeTimeline {
  BridgeTimeline({this.capacity = 500});

  final int capacity;
  final List<BridgeTimelineEvent> _events = <BridgeTimelineEvent>[];

  List<BridgeTimelineEvent> get events =>
      List<BridgeTimelineEvent>.unmodifiable(_events);

  void record(BridgeTimelineEvent event) {
    _events.add(event);
    if (_events.length > capacity) {
      _events.removeAt(0);
    }
  }

  void clear() {
    _events.clear();
  }
}
