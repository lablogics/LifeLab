import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'todos_remote_datasource.dart';
import 'todos_repository.dart';
import 'models/todo_model.dart';

final todosRemoteDataSourceProvider = Provider<TodosRemoteDataSource>((ref) {
  return TodosRemoteDataSource(ref.watch(apiClientProvider));
});

final todosRepositoryProvider = Provider<TodosRepository>((ref) {
  return TodosRepository(ref.watch(todosRemoteDataSourceProvider));
});

enum TodosFilter { all, active, completed }

class TodosState {
  final List<TodoModel> todos;
  final bool isLoading;
  final String? error;
  final TodosFilter filter;

  const TodosState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
    this.filter = TodosFilter.all,
  });

  TodosState copyWith({
    List<TodoModel>? todos,
    bool? isLoading,
    String? error,
    TodosFilter? filter,
  }) {
    return TodosState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  List<TodoModel> get filteredTodos {
    switch (filter) {
      case TodosFilter.active:
        return todos.where((t) => !t.completed).toList();
      case TodosFilter.completed:
        return todos.where((t) => t.completed).toList();
      case TodosFilter.all:
        return todos;
    }
  }
}

class TodosNotifier extends StateNotifier<TodosState> {
  final SyncEngine? _sync;
  final TodosRepository _repository;
  TodosNotifier(this._repository, [this._sync]) : super(const TodosState());

  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true);
    try {
      final todos = await _repository.getTodos();
      state = state.copyWith(todos: todos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(TodosFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<TodoModel?> createTodo(String title, {String? dueDate, String? priority}) async {
    try {
      final todo = await _repository.createTodo(
        title: title,
        dueDate: dueDate,
        priority: priority,
      );
      state = state.copyWith(todos: [todo, ...state.todos]);
      _sync?.enqueueCreate('todo', todo.id, {'title': todo.title});
      _sync?.sync();
      return todo;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> toggleTodo(String id) async {
    try {
      await _repository.toggleTodo(id);
      _sync?.enqueueUpdate('todo', id, {'completed': true});
      _sync?.sync();
      state = state.copyWith(
        todos: state.todos.map((t) {
          if (t.id == id) return t.copyWith(completed: !t.completed);
          return t;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _repository.deleteTodo(id);
      _sync?.enqueueDelete('todo', id);
      _sync?.sync();
      state = state.copyWith(
        todos: state.todos.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTodo(String id, {String? title, String? dueDate, String? priority}) async {
    try {
      await _repository.updateTodo(id, title: title, dueDate: dueDate, priority: priority);
      _sync?.enqueueUpdate('todo', id, {'title': title ?? '', 'dueDate': dueDate ?? '', 'priority': priority ?? ''});
      _sync?.sync();
      await loadTodos();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final todosProvider = StateNotifierProvider<TodosNotifier, TodosState>((ref) {
  return TodosNotifier(ref.watch(todosRepositoryProvider), ref.watch(syncEngineProvider));
});
