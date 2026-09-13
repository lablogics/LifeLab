import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'models/todo_model.dart';

class TodosRemoteDataSource {
  final ApiClient _apiClient;
  TodosRemoteDataSource(this._apiClient);

  Future<List<TodoModel>> getTodos({String? parentId, bool? completed}) async {
    final queryParameters = <String, dynamic>{};
    if (parentId != null) queryParameters['parentId'] = parentId;
    if (completed != null) queryParameters['completed'] = completed.toString();
    final response = await _apiClient.dio.dio.get(
      Endpoints.todos,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    final list = response.data as List;
    return list.map((e) => TodoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TodoModel> createTodo({
    required String title,
    String? description,
    String? parentId,
    String? noteId,
    String? priority,
    String? dueDate,
    String? recurringPattern,
  }) async {
    final response = await _apiClient.dio.dio.post(Endpoints.todos, data: {
      'title': title,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      if (noteId != null) 'noteId': noteId,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'dueDate': dueDate,
      if (recurringPattern != null) 'recurringPattern': recurringPattern,
    });
    return TodoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateTodo(String id, {
    String? title,
    bool? completed,
    String? priority,
    String? dueDate,
    String? description,
    int? position,
  }) async {
    await _apiClient.dio.dio.put('${Endpoints.todos}/$id', data: {
      if (title != null) 'title': title,
      if (completed != null) 'completed': completed,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'dueDate': dueDate,
      if (description != null) 'description': description,
      if (position != null) 'position': position,
    });
  }

  Future<void> toggleTodo(String id) async {
    await _apiClient.dio.dio.patch('${Endpoints.todos}/$id/toggle');
  }

  Future<void> deleteTodo(String id) async {
    await _apiClient.dio.dio.delete('${Endpoints.todos}/$id');
  }

  Future<void> reorderTodos(List<String> ids) async {
    await _apiClient.dio.dio.put('${Endpoints.todos}/reorder', data: {'ids': ids});
  }
}
