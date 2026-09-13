import 'models/todo_model.dart';
import 'todos_remote_datasource.dart';

class TodosRepository {
  final TodosRemoteDataSource _remote;
  TodosRepository(this._remote);

  Future<List<TodoModel>> getTodos({String? parentId, bool? completed}) =>
      _remote.getTodos(parentId: parentId, completed: completed);

  Future<TodoModel> createTodo({
    required String title,
    String? description,
    String? parentId,
    String? noteId,
    String? priority,
    String? dueDate,
    String? recurringPattern,
  }) => _remote.createTodo(
    title: title,
    description: description,
    parentId: parentId,
    noteId: noteId,
    priority: priority,
    dueDate: dueDate,
    recurringPattern: recurringPattern,
  );

  Future<void> updateTodo(
    String id, {
    String? title,
    bool? completed,
    String? priority,
    String? dueDate,
    String? description,
    int? position,
  }) => _remote.updateTodo(
    id,
    title: title,
    completed: completed,
    priority: priority,
    dueDate: dueDate,
    description: description,
    position: position,
  );

  Future<void> toggleTodo(String id) => _remote.toggleTodo(id);
  Future<void> deleteTodo(String id) => _remote.deleteTodo(id);
  Future<void> reorderTodos(List<String> ids) => _remote.reorderTodos(ids);
}
