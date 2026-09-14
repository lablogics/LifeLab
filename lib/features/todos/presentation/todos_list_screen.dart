import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/todos_providers.dart';
import '../data/models/todo_model.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class TodosListScreen extends ConsumerStatefulWidget {
  const TodosListScreen({super.key});

  @override
  ConsumerState<TodosListScreen> createState() => _TodosListScreenState();
}

class _TodosListScreenState extends ConsumerState<TodosListScreen> {
  final _inputController = TextEditingController();
  bool _showInput = false;
  bool _isBoardView = false;
  bool _bulkMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(todosProvider.notifier).loadTodos());
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosState = ref.watch(todosProvider);
    final theme = Theme.of(context);
    final filtered = todosState.filteredTodos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          IconButton(
            icon: Icon(_isBoardView ? Icons.view_list : Icons.dashboard),
            tooltip: _isBoardView ? 'List view' : 'Board view',
            onPressed: () => setState(() => _isBoardView = !_isBoardView),
          ),
          if (_bulkMode) ...[
            TextButton(onPressed: () { _selectedIds.clear(); setState(() => _bulkMode = false); }, child: const Text('Cancel')),
            if (_selectedIds.isNotEmpty) ...[
              IconButton(icon: const Icon(Icons.check_circle), tooltip: 'Complete all', onPressed: () async {
                for (final id in _selectedIds) { await ref.read(todosProvider.notifier).toggleTodo(id); }
                setState(() { _selectedIds.clear(); _bulkMode = false; });
              }),
              IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete all', onPressed: () async {
                for (final id in _selectedIds) { await ref.read(todosProvider.notifier).deleteTodo(id); }
                setState(() { _selectedIds.clear(); _bulkMode = false; });
              }),
            ],
          ] else ...[
            IconButton(icon: const Icon(Icons.checklist), tooltip: 'Select', onPressed: () => setState(() => _bulkMode = true)),
            IconButton(icon: const Icon(Icons.download), tooltip: 'Export', onPressed: _exportTodos),
          ],
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add todo',
            onPressed: () => setState(() => _showInput = true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips (scrollable for smart filters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: TodosFilter.values.map((filter) {
                final isSelected = todosState.filter == filter;
                final label = switch (filter) {
                  TodosFilter.all => 'All',
                  TodosFilter.active => 'Active',
                  TodosFilter.completed => 'Done',
                  TodosFilter.today => 'Today',
                  TodosFilter.week => 'This Week',
                  TodosFilter.high => 'High Priority',
                  TodosFilter.overdue => 'Overdue',
                };
                final count = switch (filter) {
                  TodosFilter.all => todosState.todos.length,
                  TodosFilter.active => todosState.todos.where((t) => !t.completed).length,
                  TodosFilter.completed => todosState.todos.where((t) => t.completed).length,
                  _ => todosState.filteredTodos.length,
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$label ($count)'),
                    selected: isSelected,
                    onSelected: (_) => ref.read(todosProvider.notifier).setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          // Inline input
          if (_showInput)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'What needs to be done?',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: _addTodo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    tooltip: 'Set due date',
                    onPressed: () => _pickDueDate(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _addTodo(_inputController.text),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _inputController.clear();
                      setState(() => _showInput = false);
                    },
                  ),
                ],
              ),
            ),
          // Todos list or board view
          Expanded(
            child: todosState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : todosState.error != null
                    ? Center(child: Text('Error: ${todosState.error}'))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.outline),
                                const SizedBox(height: 16),
                                Text(
                                  todosState.filter == TodosFilter.completed
                                      ? 'No completed todos'
                                      : todosState.filter == TodosFilter.active
                                          ? 'All caught up!'
                                          : 'No todos yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _isBoardView
                            ? _buildBoardView(context, todosState, theme)
                            : RefreshIndicator(
                                onRefresh: () => ref.read(todosProvider.notifier).loadTodos(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filtered.where((t) => t.parentId == null).length,
                                  itemBuilder: (context, index) {
                                    final todo = filtered.where((t) => t.parentId == null).toList()[index];
                                    final subtasks = todosState.subtasksOf(todo.id).where((t) => filtered.contains(t)).toList();
                                    return _TodoTile(
                                      todo: todo,
                                      subtasks: subtasks,
                                      onToggle: () => ref.read(todosProvider.notifier).toggleTodo(todo.id),
                                      onDelete: () => _confirmDelete(context, todo),
                                      onEdit: () => _editTodo(context, todo),
                                      onAddSubtask: () => _addSubtask(context, todo),
                                      bulkMode: _bulkMode,
                                      selected: _selectedIds.contains(todo.id),
                                      onSelect: () {
                                        setState(() {
                                          _selectedIds.contains(todo.id) ? _selectedIds.remove(todo.id) : _selectedIds.add(todo.id);
                                        });
                                      },
                                      onToggleFavorite: () => _toggleFavorite(todo),
                                    );
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  void _addTodo(String text) async {
    final title = text.trim();
    if (title.isEmpty) return;
    await ref.read(todosProvider.notifier).createTodo(title);
    _inputController.clear();
    setState(() => _showInput = false);
  }


  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
    }
  }

  void _confirmDelete(BuildContext context, TodoModel todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Todo?'),
        content: Text('"${todo.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(todosProvider.notifier).deleteTodo(todo.id);
    }
  }

  void _addSubtask(BuildContext context, TodoModel parent) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Subtask of "${parent.title}"'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Subtask title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await ref.read(todosProvider.notifier).createSubtask(parent.id, title);
    }
  }

  void _editTodo(BuildContext context, TodoModel todo) async {
    final titleCtrl = TextEditingController(text: todo.title);
    final descCtrl = TextEditingController(text: todo.description ?? '');
    String? selectedPriority = todo.priority;
    String? selectedReminder = todo.reminderType ?? 'none';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Todo'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: selectedPriority, decoration: const InputDecoration(labelText: 'Priority'),
              items: const [DropdownMenuItem(value: 'none', child: Text('None')), DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')), DropdownMenuItem(value: 'high', child: Text('High'))],
              onChanged: (v) { if (v != null) selectedPriority = v; }),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: selectedReminder, decoration: const InputDecoration(labelText: 'Reminder'),
              items: const [DropdownMenuItem(value: 'none', child: Text('None')), DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')), DropdownMenuItem(value: 'date', child: Text('On date'))],
              onChanged: (v) { if (v != null) selectedReminder = v; }),
            if (todo.noteId != null) const SizedBox(height: 8),
            if (todo.noteId != null)
              InkWell(
                onTap: () { Navigator.pop(ctx); context.push('/notes/${todo.noteId}'); },
                child: Row(children: [const Icon(Icons.link, size: 16), const SizedBox(width: 4), Text('Linked note: ${todo.noteId}', style: Theme.of(ctx).textTheme.bodySmall)]),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'title': titleCtrl.text.trim(), 'desc': descCtrl.text.trim(), 'priority': selectedPriority ?? 'none', 'reminder': selectedReminder ?? 'none'}),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result['title']!.isNotEmpty && result['title'] != todo.title) {
      ref.read(todosProvider.notifier).updateTodo(todo.id,
        title: result['title'], priority: result['priority']);
    }
  }

  Widget _buildBoardView(BuildContext context, TodosState todosState, ThemeData theme) {
    final active = todosState.todos.where((t) => !t.completed && t.parentId == null).toList();
    final completed = todosState.todos.where((t) => t.completed && t.parentId == null).toList();
    final highPriority = todosState.todos.where((t) => !t.completed && t.priority == 'high' && t.parentId == null).toList();
    return Row(children: [
      _boardColumn('To Do', active, theme, Colors.blue),
      _boardColumn('In Progress', highPriority, theme, Colors.orange),
      _boardColumn('Done', completed, theme, Colors.green),
    ]);
  }

  Widget _boardColumn(String title, List<TodoModel> todos, ThemeData theme, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${todos.length}', style: theme.textTheme.labelSmall),
          ])),
          const Divider(height: 1),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: todos.length,
            itemBuilder: (_, i) {
              final t = todos[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: Checkbox(value: t.completed, onChanged: (_) => ref.read(todosProvider.notifier).toggleTodo(t.id), visualDensity: VisualDensity.compact),
                  title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(decoration: t.completed ? TextDecoration.lineThrough : null)),
                  subtitle: t.dueDate != null ? Text(t.dueDate!, style: theme.textTheme.bodySmall) : null,
                  trailing: t.priority != 'none' ? Icon(Icons.flag, size: 14, color: t.priority == 'high' ? Colors.red : t.priority == 'medium' ? Colors.orange : Colors.blue) : null,
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _exportTodos() async {
    final todos = ref.read(todosProvider).todos;
    final jsonStr = jsonEncode(todos.map((t) => t.toJson()).toList());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Export Todos'),
      content: SelectableText(jsonStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  Future<void> _toggleFavorite(TodoModel todo) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.put('${Endpoints.todos}/${todo.id}', data: {'favorite': !(todo.priority == 'high')});
    } catch (_) {}
  }
}

class _TodoTile extends StatelessWidget {
  final TodoModel todo;
  final List<TodoModel> subtasks;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onAddSubtask;
  final bool bulkMode;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;

  const _TodoTile({
    required this.todo,
    this.subtasks = const [],
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.onAddSubtask,
    this.bulkMode = false,
    this.selected = false,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = todo.dueDate != null &&
        !todo.completed &&
        DateTime.tryParse(todo.dueDate!)?.isBefore(DateTime.now()) == true;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: selected ? theme.colorScheme.primaryContainer : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  if (bulkMode)
                    Checkbox(value: selected, onChanged: (_) => onSelect(), visualDensity: VisualDensity.compact)
                  else
                    Checkbox(
                      value: todo.completed,
                      onChanged: (_) => onToggle(),
                    ),
                  Expanded(
                    child: InkWell(
                      onTap: onEdit,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: todo.completed ? TextDecoration.lineThrough : null,
                              color: todo.completed ? theme.colorScheme.outline : null,
                            ),
                          ),
                          if (todo.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: isOverdue ? Colors.red : theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    todo.dueDate!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isOverdue ? Colors.red : theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (todo.priority != 'none')
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.flag,
                        size: 16,
                        color: _priorityColor(todo.priority),
                      ),
                    ),
                  if (onAddSubtask != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Add subtask',
                      onPressed: onAddSubtask,
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
            ),
          ),
          if (subtasks.isNotEmpty)
            ...subtasks.map((st) => Padding(
              padding: const EdgeInsets.only(left: 32, right: 16),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  dense: true,
                  leading: Checkbox(value: st.completed, onChanged: (_) {}, visualDensity: VisualDensity.compact),
                  title: Text(st.title, style: TextStyle(decoration: st.completed ? TextDecoration.lineThrough : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            )),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(todo.completed ? Icons.undo : Icons.check_circle),
              title: Text(todo.completed ? 'Mark Active' : 'Mark Done'),
              onTap: () {
                Navigator.pop(ctx);
                onToggle();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorite'),
              onTap: () {
                Navigator.pop(ctx);
                onToggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    return switch (priority) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      'low' => Colors.blue,
      _ => Colors.grey,
    };
  }
}
