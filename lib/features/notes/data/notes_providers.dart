import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'notes_remote_datasource.dart';
import 'notes_repository.dart';
import 'models/note_model.dart';
import 'models/folder_model.dart';
import 'models/tag_model.dart';

// ── Infrastructure providers ──

final notesRemoteDataSourceProvider = Provider<NotesRemoteDataSource>((ref) {
  return NotesRemoteDataSource(ref.watch(apiClientProvider));
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(notesRemoteDataSourceProvider));
});

// ── Notes state ──

enum NotesSortMode { updated, created, title }
enum NotesViewMode { list, grid }

class NotesState {
  final List<NoteModel> notes;
  final bool isLoading;
  final String? error;
  final String? selectedFolderId;
  final String? selectedTagId;
  final String searchQuery;
  final NotesSortMode sortMode;
  final NotesViewMode viewMode;
  final bool starredOnly;
  final Set<String> selectedIds;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.selectedFolderId,
    this.selectedTagId,
    this.searchQuery = '',
    this.sortMode = NotesSortMode.updated,
    this.viewMode = NotesViewMode.list,
    this.starredOnly = false,
    this.selectedIds = const {},
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
    String? selectedFolderId,
    String? selectedTagId,
    String? searchQuery,
    NotesSortMode? sortMode,
    NotesViewMode? viewMode,
    bool? starredOnly,
    Set<String>? selectedIds,
    bool clearFolder = false,
    bool clearTag = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFolderId: clearFolder ? null : (selectedFolderId ?? this.selectedFolderId),
      selectedTagId: clearTag ? null : (selectedTagId ?? this.selectedTagId),
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      viewMode: viewMode ?? this.viewMode,
      starredOnly: starredOnly ?? this.starredOnly,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  List<NoteModel> get filteredNotes {
    var result = List<NoteModel>.from(notes);
    if (starredOnly) {
      result = result.where((n) => n.isPinned).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.contentText.toLowerCase().contains(q),
      ).toList();
    }
    switch (sortMode) {
      case NotesSortMode.updated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NotesSortMode.created:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NotesSortMode.title:
        result.sort((a, b) => (a.title).toLowerCase().compareTo((b.title).toLowerCase()));
        break;
    }
    return result;
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final SyncEngine? _sync;
  final NotesRepository _repository;
  NotesNotifier(this._repository, [this._sync]) : super(const NotesState());

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true);
    try {
      final notes = await _repository.getNotes(
        folderId: state.selectedFolderId,
        tagId: state.selectedTagId,
      );
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectFolder(String? folderId) async {
    state = state.copyWith(
      selectedFolderId: folderId,
      clearTag: true,
    );
    await loadNotes();
  }

  Future<void> selectTag(String? tagId) async {
    state = state.copyWith(
      selectedTagId: tagId,
      clearFolder: true,
    );
    await loadNotes();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<NoteModel?> createNote({String title = 'Untitled', String? folderId}) async {
    try {
      final note = await _repository.createNote(
        title: title,
        folderId: folderId ?? state.selectedFolderId,
      );
      await loadNotes();
      _sync?.enqueueCreate('note', note.id, {'title': note.title});
      _sync?.sync();
      return note;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> trashNote(String id) async {
    try {
      await _repository.trashNote(id);
      _sync?.enqueueDelete('note', id);
      _sync?.sync();
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePin(String id, bool isPinned) async {
    try {
      await _repository.updateNote(id, isPinned: isPinned);
      _sync?.enqueueUpdate('note', id, {'isPinned': isPinned});
      _sync?.sync();
      state = state.copyWith(
        notes: state.notes.map((n) => n.id == id ? n.copyWith(isPinned: isPinned) : n).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setSortMode(NotesSortMode mode) {
    state = state.copyWith(sortMode: mode);
  }

  void setViewMode(NotesViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setStarredOnly(bool value) {
    state = state.copyWith(starredOnly: value);
  }

  void toggleSelectNote(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) { ids.remove(id); } else { ids.add(id); }
    state = state.copyWith(selectedIds: ids);
  }

  void selectAllNotes() {
    state = state.copyWith(selectedIds: state.notes.map((n) => n.id).toSet());
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: <String>{});
  }

  Future<void> bulkTrashNotes() async {
    try {
      for (final id in state.selectedIds) {
        await _repository.trashNote(id);
        _sync?.enqueueDelete('note', id);
      }
      _sync?.sync();
      state = state.copyWith(
        notes: state.notes.where((n) => !state.selectedIds.contains(n.id)).toList(),
        selectedIds: <String>{},
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref.watch(notesRepositoryProvider), ref.watch(syncEngineProvider));
});

// ── Folders state ──

class FoldersState {
  final List<FolderModel> folders;
  final bool isLoading;
  final String? error;

  const FoldersState({this.folders = const [], this.isLoading = false, this.error});

  FoldersState copyWith({List<FolderModel>? folders, bool? isLoading, String? error}) {
    return FoldersState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FoldersNotifier extends StateNotifier<FoldersState> {
  final NotesRepository _repository;
  FoldersNotifier(this._repository) : super(const FoldersState());

  Future<void> loadFolders() async {
    state = state.copyWith(isLoading: true);
    try {
      final folders = await _repository.getFolders();
      state = state.copyWith(folders: folders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createFolder(String name) async {
    try {
      await _repository.createFolder(name);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameFolder(String id, String name) async {
    try {
      await _repository.updateFolder(id, name: name);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _repository.deleteFolder(id);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final foldersProvider = StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  return FoldersNotifier(ref.watch(notesRepositoryProvider));
});

// ── Tags state ──

class TagsState {
  final List<TagModel> tags;
  final bool isLoading;
  final String? error;

  const TagsState({this.tags = const [], this.isLoading = false, this.error});

  TagsState copyWith({List<TagModel>? tags, bool? isLoading, String? error}) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TagsNotifier extends StateNotifier<TagsState> {
  final NotesRepository _repository;
  TagsNotifier(this._repository) : super(const TagsState());

  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true);
    try {
      final tags = await _repository.getTags();
      state = state.copyWith(tags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createTag(String name, {String color = 'gray'}) async {
    try {
      await _repository.createTag(name, color: color);
      await loadTags();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameTag(String id, String name) async {
    try {
      await _repository.updateTag(id, name: name);
      await loadTags();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _repository.deleteTag(id);
      await loadTags();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final tagsProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) {
  return TagsNotifier(ref.watch(notesRepositoryProvider));
});
