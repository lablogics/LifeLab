import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todos_providers.dart';
import '../data/models/todo_model.dart';

class TodosListScreen extends ConsumerStatefulWidget {
  const TodosListScreen({super.key});

  @override
  ConsumerState<TodosListScreen> createState() => _TodosListScreenState();
}

class _TodosListScreenState extends ConsumerState<TodosListScreen> {
  final _inputController = TextEditingController();
  bool _showInput = false;

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
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar view',
            onPressed: () => _showCalendarView(context, todosState),
          ),
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
          // Todos list
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

  void _showCalendarView(BuildContext context, TodosState todosState) {
    final now = DateTime.now();
    final todosWithDue = todosState.todos.where((t) => t.dueDate != null && !t.completed).toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('Calendar View', style: Theme.of(ctx).textTheme.titleLarge)),
          Expanded(child: ListView.builder(
            controller: scrollController,
            itemCount: 14,
            itemBuilder: (ctx, i) {
              final day = now.add(Duration(days: i));
              final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final dayTodos = todosWithDue.where((t) => t.dueDate!.startsWith(dayStr)).toList();
              if (dayTodos.isEmpty && i > 0) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text(
                  i == 0 ? 'Today' : i == 1 ? 'Tomorrow' : '${day.weekday.toString().substring(0, 3)} ${day.day}/${day.month}',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                )),
                ...dayTodos.map((t) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: t.priority != 'none' ? Text('Priority: ${t.priority}') : null,
                )),
              ]);
            },
          )),
        ]),
      ),
    );
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
    final controller = TextEditingController(text: todo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != todo.title) {
      ref.read(todosProvider.notifier).updateTodo(todo.id, title: result);
    }
  }
}

class _TodoTile extends StatelessWidget {
  final TodoModel todo;
  final List<TodoModel> subtasks;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onAddSubtask;

  const _TodoTile({
    required this.todo,
    this.subtasks = const [],
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.onAddSubtask,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
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
