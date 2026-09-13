import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';
import '../data/projects_providers.dart';
import '../data/models/project_model.dart';

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
    final theme = Theme.of(context);
    final columns = _boardDetail?['columns'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBoard?.name ?? 'Board'),
        actions: [
          if (_boards.length > 1)
            PopupMenuButton<BoardModel>(
              icon: const Icon(Icons.view_list),
              onSelected: (board) => _loadBoardDetail(board.id),
              itemBuilder: (ctx) => _boards.map((b) => PopupMenuItem(value: b, child: Text(b.name))).toList(),
            ),
          IconButton(icon: const Icon(Icons.view_column), tooltip: 'Add Column', onPressed: () => _addColumn(context)),
          IconButton(icon: const Icon(Icons.add), tooltip: 'Add Board', onPressed: () => _addBoard(context)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : columns == null || columns.isEmpty
              ? Center(child: Text('No columns yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columns.map((col) {
                      final column = BoardColumnModel.fromJson(col as Map<String, dynamic>);
                      return _KanbanColumn(
                        column: column,
                        boardId: _selectedBoard!.id,
                        onAddCard: () => _addCard(context, column),
                        onDeleteCard: (cardId) => _deleteCard(context, cardId),
                      );
                    }).toList(),
                  ),
                ),
    );
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

  const _KanbanColumn({
    required this.column, required this.boardId,
    required this.onAddCard, required this.onDeleteCard,
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
            child: column.cards.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No cards')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: column.cards.length,
                    itemBuilder: (context, index) {
                      final card = column.cards[index];
                      return Dismissible(
                        key: Key(card.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 12),
                          child: const Icon(Icons.delete, color: Colors.red, size: 18),
                        ),
                        onDismissed: (_) => onDeleteCard(card.id),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(card.title, style: theme.textTheme.bodyMedium),
                          ),
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
