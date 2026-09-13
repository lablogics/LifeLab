import 'models/project_model.dart';
import 'projects_remote_datasource.dart';

class ProjectsRepository {
  final ProjectsRemoteDataSource _remote;
  ProjectsRepository(this._remote);

  Future<List<ProjectModel>> getProjects() => _remote.getProjects();
  Future<ProjectModel> getProject(String id) => _remote.getProject(id);
  Future<ProjectModel> createProject(String name, {String? description, String? color}) =>
      _remote.createProject(name, description: description, color: color);
  Future<void> updateProject(String id, {String? name, String? description, String? color, String? status}) =>
      _remote.updateProject(id, name: name, description: description, color: color, status: status);
  Future<void> deleteProject(String id) => _remote.deleteProject(id);

  Future<List<BoardModel>> getBoards(String projectId) => _remote.getBoards(projectId);
  Future<Map<String, dynamic>> getBoardDetail(String boardId) => _remote.getBoardDetail(boardId);
  Future<BoardModel> createBoard(String name, {String? projectId}) =>
      _remote.createBoard(name, projectId: projectId);
  Future<void> deleteBoard(String id) => _remote.deleteBoard(id);

  Future<CardModel> createCard(String columnId, String boardId, String title) =>
      _remote.createCard(columnId, boardId, title);
  Future<void> updateCard(String id, {String? title, String? columnId, int? position}) =>
      _remote.updateCard(id, title: title, columnId: columnId, position: position);
  Future<void> deleteCard(String id) => _remote.deleteCard(id);

  Future<void> addColumn(String boardId, String name) => _remote.addColumn(boardId, name);
  Future<void> deleteColumn(String id) => _remote.deleteColumn(id);
}
