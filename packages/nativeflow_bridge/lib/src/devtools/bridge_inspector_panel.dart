import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bridge_timeline.dart';

/// Drop-in Flutter widget for inspecting bridge activity inside a running app.
///
/// Use [BridgeInspectorPanel] in a debug-only route or floating window to see
/// live bridge calls, events, latencies, and errors. The panel reads from
/// [BridgeInspector.instance] by default and never holds raw payloads unless
/// the application has explicitly enabled `capturePayloads`.
class BridgeInspectorPanel extends StatefulWidget {
  const BridgeInspectorPanel({
    super.key,
    BridgeInspector? inspector,
    this.title = 'NativeFlow Bridge Inspector',
  }) : _inspector = inspector;

  final BridgeInspector? _inspector;
  final String title;

  BridgeInspector get _resolvedInspector =>
      _inspector ?? BridgeInspector.instance;

  @override
  State<BridgeInspectorPanel> createState() => _BridgeInspectorPanelState();
}

class _BridgeInspectorPanelState extends State<BridgeInspectorPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StreamSubscription<BridgeTimelineEvent>? _subscription;
  BridgeTimelineEvent? _selected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subscription = widget._resolvedInspector.events.listen(
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspector = widget._resolvedInspector;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(
            title: widget.title,
            inspector: inspector,
            onClear: () {
              setState(() {
                inspector.clear();
                _selected = null;
              });
            },
            onExport: () => _copyExport(context, inspector),
          ),
          TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Timeline'),
              Tab(text: 'Stats'),
              Tab(text: 'Errors'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _TimelineTab(
                  events: inspector.timeline.reversed.toList(),
                  selected: _selected,
                  onSelect: (event) => setState(() => _selected = event),
                ),
                _StatsTab(stats: inspector.stats),
                _ErrorsTab(
                  events: inspector.timeline
                      .where((event) => event.errorCode != null)
                      .toList()
                      .reversed
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyExport(
    BuildContext context,
    BridgeInspector inspector,
  ) async {
    await Clipboard.setData(ClipboardData(text: inspector.exportJson()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Bridge inspector export copied.')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.inspector,
    required this.onClear,
    required this.onExport,
  });

  final String title;
  final BridgeInspector inspector;
  final VoidCallback onClear;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (kDebugMode)
            IconButton(
              tooltip: 'Toggle payload capture',
              icon: Icon(
                inspector.capturePayloads ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                inspector.capturePayloads = !inspector.capturePayloads;
              },
            ),
          IconButton(
            tooltip: 'Copy export JSON',
            icon: const Icon(Icons.download),
            onPressed: onExport,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({
    required this.events,
    required this.selected,
    required this.onSelect,
  });

  final List<BridgeTimelineEvent> events;
  final BridgeTimelineEvent? selected;
  final ValueChanged<BridgeTimelineEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyState(message: 'No bridge calls captured yet.');
    }
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return _TimelineRow(
                event: event,
                isSelected: selected?.id == event.id,
                onTap: () => onSelect(event),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: selected == null
              ? const _EmptyState(message: 'Select an entry to inspect.')
              : _DetailView(event: selected!),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  final BridgeTimelineEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, event.status);
    final duration = event.duration;
    return ListTile(
      selected: isSelected,
      dense: true,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        '${event.channel} • ${event.operation}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${event.kind.name} • ${event.status.name}'
        '${duration != null ? ' • ${duration.inMicroseconds}µs' : ''}'
        '${event.errorCode != null ? ' • ${event.errorCode}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }

  Color _statusColor(BuildContext context, BridgeOperationStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      BridgeOperationStatus.success => Colors.green,
      BridgeOperationStatus.error => scheme.error,
      BridgeOperationStatus.timeout => Colors.orange,
      BridgeOperationStatus.cancelled => Colors.grey,
      BridgeOperationStatus.started => scheme.primary,
    };
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.event});

  final BridgeTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_DetailRow>[
      _DetailRow('Bridge', event.bridge),
      _DetailRow('Channel', event.channel),
      _DetailRow('Operation', event.operation),
      _DetailRow('Kind', event.kind.name),
      _DetailRow('Status', event.status.name),
      _DetailRow('Transport', event.transport ?? '—'),
      _DetailRow('Started', event.startedAt.toIso8601String()),
      _DetailRow('Completed', event.completedAt?.toIso8601String() ?? '—'),
      _DetailRow(
        'Duration',
        event.duration == null
            ? '—'
            : '${event.duration!.inMicroseconds} µs',
      ),
      _DetailRow('Request bytes', '${event.requestBytes ?? 0}'),
      _DetailRow('Response bytes', '${event.responseBytes ?? 0}'),
      if (event.errorCode != null) _DetailRow('Error code', event.errorCode!),
      if (event.errorMessage != null)
        _DetailRow('Error message', event.errorMessage!),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...rows,
          if (event.requestPreview != null) ...<Widget>[
            const SizedBox(height: 8),
            Text('Request preview', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _PreviewBlock(value: event.requestPreview),
          ],
          if (event.responsePreview != null) ...<Widget>[
            const SizedBox(height: 8),
            Text('Response preview', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _PreviewBlock(value: event.responsePreview),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SelectableText(
        value.toString(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});

  final List<BridgeOperationStats> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const _EmptyState(message: 'No stats yet.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('Channel')),
          DataColumn(label: Text('Operation')),
          DataColumn(label: Text('Calls'), numeric: true),
          DataColumn(label: Text('Errors'), numeric: true),
          DataColumn(label: Text('Timeouts'), numeric: true),
          DataColumn(label: Text('Avg µs'), numeric: true),
          DataColumn(label: Text('Min µs'), numeric: true),
          DataColumn(label: Text('Max µs'), numeric: true),
        ],
        rows: stats
            .map(
              (stat) => DataRow(
                cells: <DataCell>[
                  DataCell(Text(stat.channel)),
                  DataCell(Text(stat.operation)),
                  DataCell(Text('${stat.totalCalls}')),
                  DataCell(Text('${stat.errorCount}')),
                  DataCell(Text('${stat.timeoutCount}')),
                  DataCell(Text(stat.averageMicros.toStringAsFixed(1))),
                  DataCell(Text('${stat.minMicros}')),
                  DataCell(Text('${stat.maxMicros}')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ErrorsTab extends StatelessWidget {
  const _ErrorsTab({required this.events});

  final List<BridgeTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyState(message: 'No errors captured.');
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          dense: true,
          title: Text('${event.channel} • ${event.operation}'),
          subtitle: Text(
            '${event.errorCode ?? 'error'} — ${event.errorMessage ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
