import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'models/project_model.dart';

class ProjectsRemoteDataSource {
  final ApiClient _api;
  ProjectsRemoteDataSource(this._api);

  // ── Projects ──

  Future<List<ProjectModel>> getProjects() async {
    final r = await _api.dio.dio.get(Endpoints.projects);
    return (r.data as List).map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final r = await _api.dio.dio.get('${Endpoints.projects}/$id');
    return ProjectModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProjectModel> createProject(String name, {String? description, String? color}) async {
    final r = await _api.dio.dio.post(Endpoints.projects, data: {
      'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
    });
    return ProjectModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateProject(String id, {String? name, String? description, String? color, String? status}) async {
    await _api.dio.dio.put('${Endpoints.projects}/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (status != null) 'status': status,
    });
  }

  Future<void> deleteProject(String id) async {
    await _api.dio.dio.delete('${Endpoints.projects}/$id');
  }

  // ── Boards ──

  Future<List<BoardModel>> getBoards(String projectId) async {
    final r = await _api.dio.dio.get('${Endpoints.boards}/$projectId');
    return (r.data as List).map((e) => BoardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getBoardDetail(String boardId) async {
    final r = await _api.dio.dio.get('${Endpoints.boards}/detail/$boardId');
    return r.data as Map<String, dynamic>;
  }

  Future<BoardModel> createBoard(String name, {String? projectId}) async {
    final r = await _api.dio.dio.post(Endpoints.boards, data: {
      'name': name,
      if (projectId != null) 'projectId': projectId,
    });
    return BoardModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteBoard(String id) async {
    await _api.dio.dio.delete('${Endpoints.boards}/$id');
  }

  // ── Cards ──

  Future<CardModel> createCard(String columnId, String boardId, String title) async {
    final r = await _api.dio.dio.post('${Endpoints.boards}/cards', data: {
      'columnId': columnId, 'boardId': boardId, 'title': title,
    });
    return CardModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateCard(String id, {String? title, String? columnId, int? position}) async {
    await _api.dio.dio.put('${Endpoints.boards}/cards/$id', data: {
      if (title != null) 'title': title,
      if (columnId != null) 'columnId': columnId,
      if (position != null) 'position': position,
    });
  }

  Future<void> deleteCard(String id) async {
    await _api.dio.dio.delete('${Endpoints.boards}/cards/$id');
  }

  // ── Columns ──

  Future<void> addColumn(String boardId, String name) async {
    await _api.dio.dio.post('${Endpoints.boards}/columns', data: {
      'boardId': boardId, 'name': name,
    });
  }

  Future<void> deleteColumn(String id) async {
    await _api.dio.dio.delete('${Endpoints.boards}/columns/$id');
  }
}
