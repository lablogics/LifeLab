import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'models/note_model.dart';
import 'models/folder_model.dart';
import 'models/tag_model.dart';

class NotesRemoteDataSource {
  final ApiClient _apiClient;
  NotesRemoteDataSource(this._apiClient);

  // ── Notes ──

  Future<List<NoteModel>> getNotes({String? folderId, String? tagId}) async {
    final queryParameters = <String, dynamic>{};
    if (folderId != null) queryParameters['folderId'] = folderId;
    if (tagId != null) queryParameters['tagId'] = tagId;
    final response = await _apiClient.dio.dio.get(
      Endpoints.notes,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    final list = response.data as List;
    return list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NoteModel>> getTrashedNotes() async {
    final response = await _apiClient.dio.dio.get('${Endpoints.notes}/trashed');
    final list = response.data as List;
    return list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NoteModel> getNote(String id) async {
    final response = await _apiClient.dio.dio.get('${Endpoints.notes}/$id');
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteModel> createNote({
    String title = 'Untitled',
    String? contentJson,
    String? folderId,
  }) async {
    final response = await _apiClient.dio.dio.post(Endpoints.notes, data: {
      'title': title,
      if (contentJson != null) 'contentJson': contentJson,
      if (folderId != null) 'folderId': folderId,
    });
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateNote(String id, {
    String? title,
    String? contentJson,
    String? folderId,
    bool? isPinned,
    bool? isArchived,
  }) async {
    await _apiClient.dio.dio.put('${Endpoints.notes}/$id', data: {
      if (title != null) 'title': title,
      if (contentJson != null) 'contentJson': contentJson,
      if (folderId != null) 'folderId': folderId,
      if (isPinned != null) 'isPinned': isPinned,
      if (isArchived != null) 'isArchived': isArchived,
    });
  }

  Future<void> trashNote(String id) async {
    await _apiClient.dio.dio.delete('${Endpoints.notes}/$id');
  }

  Future<void> restoreNote(String id) async {
    await _apiClient.dio.dio.post('${Endpoints.notes}/$id/restore');
  }

  Future<void> permanentDeleteNote(String id) async {
    await _apiClient.dio.dio.post('${Endpoints.notes}/$id/permanent-delete');
  }

  Future<NoteModel> duplicateNote(String noteId) async {
    final response = await _apiClient.dio.dio.post(
      '${Endpoints.notes}/duplicate',
      data: {'noteId': noteId},
    );
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Folders ──

  Future<List<FolderModel>> getFolders() async {
    final response = await _apiClient.dio.dio.get(Endpoints.folders);
    final list = response.data as List;
    return list.map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FolderModel> createFolder(String name, {String? parentId}) async {
    final response = await _apiClient.dio.dio.post(Endpoints.folders, data: {
      'name': name,
      if (parentId != null) 'parentId': parentId,
    });
    return FolderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateFolder(String id, {String? name, String? parentId}) async {
    await _apiClient.dio.dio.put('${Endpoints.folders}/$id', data: {
      if (name != null) 'name': name,
      if (parentId != null) 'parentId': parentId,
    });
  }

  Future<void> deleteFolder(String id) async {
    await _apiClient.dio.dio.delete('${Endpoints.folders}/$id');
  }

  // ── Tags ──

  Future<List<TagModel>> getTags() async {
    final response = await _apiClient.dio.dio.get(Endpoints.tags);
    final list = response.data as List;
    return list.map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TagModel> createTag(String name, {String color = 'gray'}) async {
    final response = await _apiClient.dio.dio.post(Endpoints.tags, data: {
      'name': name,
      'color': color,
    });
    return TagModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateTag(String id, {String? name, String? color}) async {
    await _apiClient.dio.dio.put('${Endpoints.tags}/$id', data: {
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  Future<void> deleteTag(String id) async {
    await _apiClient.dio.dio.delete('${Endpoints.tags}/$id');
  }

  Future<List<TagModel>> getNoteTags(String noteId) async {
    final response = await _apiClient.dio.dio.get(
      '${Endpoints.tags}/notes/$noteId/tags',
    );
    final list = response.data as List;
    return list.map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addTagToNote(String noteId, String tagId) async {
    await _apiClient.dio.dio.post(
      '${Endpoints.tags}/notes/$noteId/tags',
      data: {'tagId': tagId},
    );
  }

  Future<void> removeTagFromNote(String noteId, String tagId) async {
    await _apiClient.dio.dio.delete(
      '${Endpoints.tags}/notes/$noteId/tags/$tagId',
    );
  }
}
