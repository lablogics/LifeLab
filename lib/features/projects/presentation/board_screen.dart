import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/projects_providers.dart';
import '../data/models/project_model.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String projectId;
  const BoardScreen({super.key, required this.projectId});
  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  List<BoardModel> _boards = [];
  BoardModel? _selectedBoard;
  Map<String, dynamic>? _boardDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final boards = await repo.getBoards(widget.projectId);
      setState(() {
        _boards = boards;
        _isLoading = false;
      });
      if (boards.isNotEmpty && _selectedBoard == null) {
        await _loadBoardDetail(boards.first.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBoardDetail(String boardId) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final detail = await repo.getBoardDetail(boardId);
      setState(() {
        _selectedBoard = BoardModel.fromJson(detail);
        _boardDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedBoard?.name ?? 'Project'),
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Board', icon: Icon(Icons.view_column, size: 16)),
              Tab(text: 'Time', icon: Icon(Icons.timer, size: 16)),
              Tab(text: 'Activity', icon: Icon(Icons.history, size: 16)),
              Tab(text: 'Files', icon: Icon(Icons.folder, size: 16)),
              Tab(text: 'Details', icon: Icon(Icons.info, size: 16)),
            ],
          ),
          actions: [
            if (_boards.length > 1)
              PopupMenuButton<BoardModel>(
                icon: const Icon(Icons.view_list),
                onSelected: (board) => _loadBoardDetail(board.id),
                itemBuilder: (ctx) => _boards.map((b) => PopupMenuItem(value: b, child: Text(b.name))).toList(),
              ),
            IconButton(icon: const Icon(Icons.add), tooltip: 'Add Board', onPressed: () => _addBoard(context)),
          ],
        ),
        body: TabBarView(
          children: [
            _buildBoardTab(context),
            _buildTimeTab(context),
            _buildActivityTab(context),
            _buildFilesTab(context),
            _buildDetailsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardTab(BuildContext context) {
    final theme = Theme.of(context);
    final columns = _boardDetail?['columns'] as List?;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_selectedBoard == null) return Center(child: Text('No board selected', style: theme.textTheme.bodyLarge));
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8), child: FilledButton.icon(
        icon: const Icon(Icons.view_column, size: 16), label: const Text('Add Column'), onPressed: () => _addColumn(context),
      )),
      Expanded(child: columns == null || columns.isEmpty
        ? Center(child: Text('No columns yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns.map((col) {
              final column = BoardColumnModel.fromJson(col as Map<String, dynamic>);
              return _KanbanColumn(
                column: column, boardId: _selectedBoard!.id,
                onAddCard: () => _addCard(context, column),
                onDeleteCard: (cardId) => _deleteCard(context, cardId),
                onMoveCard: (cardId, toColumnId) => _moveCard(cardId, toColumnId),
              );
            }).toList()),
          )),
    ]);
  }

  Widget _buildTimeTab(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadTimeEntries(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.timer, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No time entries yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Start Timer'), onPressed: () => _startTimeEntry(context)),
        ]));
        return Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(
            icon: const Icon(Icons.add), label: const Text('Log Time'), onPressed: () => _startTimeEntry(context),
          )),
          Expanded(child: ListView.builder(itemCount: entries.length, itemBuilder: (_, i) {
            final e = entries[i];
            final duration = e['duration'] as int? ?? 0;
            final hours = duration ~/ 3600;
            final mins = (duration % 3600) ~/ 60;
            return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(
              leading: const Icon(Icons.timer),
              title: Text(e['description'] as String? ?? 'Time entry'),
              subtitle: Text('${hours}h ${mins}m - ${e['date'] ?? ''}'),
            ));
          })),
        ]);
      },
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadActivity(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final activities = snapshot.data ?? [];
        if (activities.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No activity yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
        ]));
        return ListView.builder(itemCount: activities.length, itemBuilder: (_, i) {
          final a = activities[i];
          return ListTile(
            leading: Icon(_activityIcon(a['type'] as String? ?? '')),
            title: Text(a['description'] as String? ?? a['action'] as String? ?? 'Activity'),
            subtitle: Text(a['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(a['createdAt'] as int).toLocal().toString().substring(0, 16) : ''),
          );
        });
      },
    );
  }

  Widget _buildFilesTab(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadFiles(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final files = snapshot.data ?? [];
        if (files.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.folder, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No files attached', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
        ]));
        return ListView.builder(itemCount: files.length, itemBuilder: (_, i) {
          final f = files[i];
          return ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(f['name'] as String? ?? 'File'),
            subtitle: Text(f['size'] != null ? '${((f['size'] as int) / 1024).toStringAsFixed(1)} KB' : ''),
          );
        });
      },
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _boardDetail;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(detail?['name'] as String? ?? 'Project Details', style: theme.textTheme.titleLarge),
      const SizedBox(height: 16),
      if (detail?['description'] != null) Text(detail!['description'] as String, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.calendar_today), title: Text('Created: ${detail?['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(detail!['createdAt'] as int).toLocal().toString().substring(0, 10) : 'N/A'}'))),
      Card(child: ListTile(leading: const Icon(Icons.update), title: Text('Updated: ${detail?['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(detail!['updatedAt'] as int).toLocal().toString().substring(0, 10) : 'N/A'}'))),
    ]);
  }

  // ── Data loading helpers ──
  Future<List<Map<String, dynamic>>> _loadTimeEntries() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.projects}/${widget.projectId}/time');
      return ((r.data as Map<String, dynamic>)['items'] as List? ?? (r.data as List? ?? [])).cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> _loadActivity() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.projects}/${widget.projectId}/activity');
      return ((r.data as Map<String, dynamic>)['items'] as List? ?? (r.data as List? ?? [])).cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> _loadFiles() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.projects}/${widget.projectId}/files');
      return ((r.data as Map<String, dynamic>)['items'] as List? ?? (r.data as List? ?? [])).cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  void _startTimeEntry(BuildContext context) {
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '0');
    final minsCtrl = TextEditingController(text: '0');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Log Time'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Hours'), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: minsCtrl, decoration: const InputDecoration(labelText: 'Minutes'), keyboardType: TextInputType.number)),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            final api = ref.read(apiClientProvider);
            final duration = (int.tryParse(hoursCtrl.text) ?? 0) * 3600 + (int.tryParse(minsCtrl.text) ?? 0) * 60;
            await api.dio.dio.post('${Endpoints.projects}/${widget.projectId}/time', data: {'description': descCtrl.text, 'duration': duration});
          } catch (_) {}
        }, child: const Text('Log')),
      ],
    ));
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'card.created': return Icons.add_circle;
      case 'card.moved': return Icons.move_down;
      case 'card.deleted': return Icons.delete;
      case 'board.created': return Icons.view_column;
      default: return Icons.circle;
    }
  }

  void _addBoard(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Board'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Board name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final repo = ref.read(projectsRepositoryProvider);
      await repo.createBoard(name, projectId: widget.projectId);
      _loadBoards();
    }
  }

  void _addColumn(BuildContext context) async {
    if (_selectedBoard == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Column'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Column name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final repo = ref.read(projectsRepositoryProvider);
      await repo.addColumn(_selectedBoard!.id, name);
      _loadBoardDetail(_selectedBoard!.id);
    }
  }

  void _addCard(BuildContext context, BoardColumnModel column) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Card'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Card title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      final repo = ref.read(projectsRepositoryProvider);
      await repo.createCard(column.id, _selectedBoard!.id, title);
      _loadBoardDetail(_selectedBoard!.id);
    }
  }

  void _moveCard(String cardId, String toColumnId) async {
    final repo = ref.read(projectsRepositoryProvider);
    await repo.updateCard(cardId, columnId: toColumnId);
    _loadBoardDetail(_selectedBoard!.id);
  }

  void _deleteCard(BuildContext context, String cardId) async {
    final repo = ref.read(projectsRepositoryProvider);
    await repo.deleteCard(cardId);
    _loadBoardDetail(_selectedBoard!.id);
  }
}

class _KanbanColumn extends StatelessWidget {
  final BoardColumnModel column;
  final String boardId;
  final VoidCallback onAddCard;
  final void Function(String cardId) onDeleteCard;
  final void Function(String cardId, String toColumnId)? onMoveCard;

  const _KanbanColumn({
    required this.column, required this.boardId,
    required this.onAddCard, required this.onDeleteCard,
    this.onMoveCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
            child: Row(
              children: [
                Text(column.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('(${column.cards.length})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.add, size: 18), visualDensity: VisualDensity.compact, onPressed: onAddCard),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: DragTarget<Map<String, String>>(
              onAcceptWithDetails: (details) {
                final data = details.data;
                if (data['fromColumnId'] != column.id) {
                  onMoveCard?.call(data['cardId']!, column.id);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isTargeted = candidateData.isNotEmpty;
                return Container(
                  decoration: isTargeted ? BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ) : null,
                  child: column.cards.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No cards')))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: column.cards.length,
                    itemBuilder: (context, index) {
                      final card = column.cards[index];
                      return LongPressDraggable<Map<String, String>>(
                        key: Key(card.id),
                        data: {'cardId': card.id, 'fromColumnId': column.id},
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 240,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(card.title, style: theme.textTheme.bodyMedium),
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(card.title, style: theme.textTheme.bodyMedium),
                            ),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(child: Text(card.title, style: theme.textTheme.bodyMedium)),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 16), onPressed: () => onDeleteCard(card.id), visualDensity: VisualDensity.compact),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
