import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:go_router/go_router.dart';

class _GraphNode { final String id; final String title; double x, y, vx, vy; int connections; final Color color;
  _GraphNode({required this.id, required this.title, required this.x, required this.y, this.vx = 0, this.vy = 0, this.connections = 0, this.color = Colors.blue}); }
class _GraphEdge { final String sourceId; final String targetId;
  _GraphEdge({required this.sourceId, required this.targetId}); }

class GraphState { final List<_GraphNode> nodes; final List<_GraphEdge> edges; final bool isLoading; final String? hoveredId;
  const GraphState({this.nodes = const [], this.edges = const [], this.isLoading = false, this.hoveredId = null});
  GraphState copyWith({List<_GraphNode>? nodes, List<_GraphEdge>? edges, bool? isLoading, String? hoveredId}) =>
    GraphState(nodes: nodes ?? this.nodes, edges: edges ?? this.edges, isLoading: isLoading ?? this.isLoading, hoveredId: hoveredId ?? this.hoveredId); }

class GraphNotifier extends StateNotifier<GraphState> {
  final ApiClient _api;
  GraphNotifier(this._api) : super(const GraphState());
  final Map<String, Color> _tagColorMap = {'red': Colors.red, 'blue': Colors.blue, 'green': Colors.green, 'purple': Colors.purple, 'yellow': Colors.amber, 'gray': Colors.grey, 'orange': Colors.orange, 'pink': Colors.pink, 'teal': Colors.teal};

  Future<void> loadGraph() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.notesWithTags);
      final notes = (r.data is List ? r.data as List : (r.data as Map<String, dynamic>)['items'] as List? ?? []);
      final rng = Random(42);
      final nodes = <_GraphNode>[];
      final edges = <_GraphEdge>[];
      final noteIds = <String>{};
      for (final n in notes) {
        final note = n as Map<String, dynamic>;
        final id = note['id'] as String;
        noteIds.add(id);
        final tags = (note['tags'] as List? ?? []);
        final tagColor = tags.isNotEmpty ? (tags.first as Map<String, dynamic>)['tagColor'] as String? ?? 'blue' : 'blue';
        nodes.add(_GraphNode(id: id, title: note['title'] as String? ?? 'Untitled', x: rng.nextDouble() * 300, y: rng.nextDouble() * 500, color: _tagColorMap[tagColor] ?? Colors.blue));
        // Extract links from contentJson
        final contentJson = note['contentJson'] as String?;
        if (contentJson != null) {
          try { _extractLinks(contentJson, id, edges); } catch (_) {}
        }
      }
      // Count connections
      for (final e in edges) {
        final s = nodes.where((n) => n.id == e.sourceId);
        final t = nodes.where((n) => n.id == e.targetId);
        if (s.isNotEmpty) s.first.connections++;
        if (t.isNotEmpty) t.first.connections++;
      }
      // Filter edges to only include known nodes
      final validEdges = edges.where((e) => noteIds.contains(e.sourceId) && noteIds.contains(e.targetId)).toList();
      state = state.copyWith(nodes: nodes, edges: validEdges, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }

  void _extractLinks(String contentJson, String noteId, List<_GraphEdge> edges) {
    // Simple regex-based extraction of note IDs from wikilink patterns
    final regex = RegExp(r'"noteId"\s*:\s*"([^"]+)"');
    for (final m in regex.allMatches(contentJson)) {
      final targetId = m.group(1);
      if (targetId != null && targetId != noteId) {
        edges.add(_GraphEdge(sourceId: noteId, targetId: targetId));
      }
    }
  }
}

final graphProvider = StateNotifierProvider<GraphNotifier, GraphState>((ref) => GraphNotifier(ref.watch(apiClientProvider)));

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});
  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..addListener(() { if (mounted) setState(() {}); });
    Future.microtask(() => ref.read(graphProvider.notifier).loadGraph());
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(graphProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Graph'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(graphProvider.notifier).loadGraph()),
        IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: () => _showAnalytics(state)),
      ]),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.nodes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.hub_outlined, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No notes to graph')]))
              : GestureDetector(
                  onPanUpdate: (d) {
                    // Simple drag to pan
                    for (final n in state.nodes) { n.x += d.delta.dx; n.y += d.delta.dy; }
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _GraphPainter(nodes: state.nodes, edges: state.edges, theme: theme),
                    child: Stack(
                      children: state.nodes.map((n) => Positioned(
                        left: n.x - 20, top: n.y - 20,
                        child: GestureDetector(
                          onTap: () => context.push('/notes/${n.id}'),
                          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: n.color.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: n.color, width: 2)),
                            child: Center(child: Text(n.title.isNotEmpty ? n.title[0].toUpperCase() : '?', style: TextStyle(color: n.color, fontWeight: FontWeight.bold, fontSize: 14))),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
    );
  }

  void _showAnalytics(GraphState state) {
    final sorted = List<_GraphNode>.from(state.nodes)..sort((a, b) => b.connections.compareTo(a.connections));
    final top = sorted.take(5).where((n) => n.connections > 0).toList();
    final orphans = sorted.where((n) => n.connections == 0).toList();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Graph Analytics'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total notes: ${state.nodes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Connections: ${state.edges.length}'),
        const SizedBox(height: 12),
        if (top.isNotEmpty) ...[const Text('Most connected:', style: TextStyle(fontWeight: FontWeight.bold)), ...top.map((n) => Text('  ${n.title} (${n.connections})'))],
        const SizedBox(height: 8),
        Text('Orphan notes: ${orphans.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }
}

class _GraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final ThemeData theme;
  _GraphPainter({required this.nodes, required this.edges, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final linePaint = Paint()..color = theme.colorScheme.outline.withOpacity(0.3)..strokeWidth = 1;
    for (final e in edges) {
      final s = nodeMap[e.sourceId];
      final t = nodeMap[e.targetId];
      if (s != null && t != null) canvas.drawLine(Offset(s.x, s.y), Offset(t.x, t.y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}
