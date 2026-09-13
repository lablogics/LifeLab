import 'models/note_model.dart';
import 'models/folder_model.dart';
import 'models/tag_model.dart';
import 'notes_remote_datasource.dart';

class NotesRepository {
  final NotesRemoteDataSource _remote;
  NotesRepository(this._remote);

  // ── Notes ──

  Future<List<NoteModel>> getNotes({String? folderId, String? tagId}) =>
      _remote.getNotes(folderId: folderId, tagId: tagId);

  Future<List<NoteModel>> getTrashedNotes() => _remote.getTrashedNotes();

  Future<NoteModel> getNote(String id) => _remote.getNote(id);

  Future<NoteModel> createNote({
    String title = 'Untitled',
    String? contentJson,
    String? folderId,
  }) => _remote.createNote(title: title, contentJson: contentJson, folderId: folderId);

  Future<void> updateNote(
    String id, {
    String? title,
    String? contentJson,
    String? folderId,
    bool? isPinned,
    bool? isArchived,
  }) => _remote.updateNote(
    id,
    title: title,
    contentJson: contentJson,
    folderId: folderId,
    isPinned: isPinned,
    isArchived: isArchived,
  );

  Future<void> trashNote(String id) => _remote.trashNote(id);
  Future<void> restoreNote(String id) => _remote.restoreNote(id);
  Future<void> permanentDeleteNote(String id) => _remote.permanentDeleteNote(id);
  Future<NoteModel> duplicateNote(String noteId) => _remote.duplicateNote(noteId);

  // ── Folders ──

  Future<List<FolderModel>> getFolders() => _remote.getFolders();

  Future<FolderModel> createFolder(String name, {String? parentId}) =>
      _remote.createFolder(name, parentId: parentId);

  Future<void> updateFolder(String id, {String? name, String? parentId}) =>
      _remote.updateFolder(id, name: name, parentId: parentId);

  Future<void> deleteFolder(String id) => _remote.deleteFolder(id);

  // ── Tags ──

  Future<List<TagModel>> getTags() => _remote.getTags();

  Future<TagModel> createTag(String name, {String color = 'gray'}) =>
      _remote.createTag(name, color: color);

  Future<void> updateTag(String id, {String? name, String? color}) =>
      _remote.updateTag(id, name: name, color: color);

  Future<void> deleteTag(String id) => _remote.deleteTag(id);

  Future<List<TagModel>> getNoteTags(String noteId) => _remote.getNoteTags(noteId);

  Future<void> addTagToNote(String noteId, String tagId) =>
      _remote.addTagToNote(noteId, tagId);

  Future<void> removeTagFromNote(String noteId, String tagId) =>
      _remote.removeTagFromNote(noteId, tagId);
}
