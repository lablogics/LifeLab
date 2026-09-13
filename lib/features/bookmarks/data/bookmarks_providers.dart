import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'models/bookmark_model.dart';

class BookmarksState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? error;

  const BookmarksState({this.bookmarks = const [], this.isLoading = false, this.error});

  BookmarksState copyWith({List<BookmarkModel>? bookmarks, bool? isLoading, String? error}) {
    return BookmarksState(bookmarks: bookmarks ?? this.bookmarks, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  final ApiClient _api;
  BookmarksNotifier(this._api) : super(const BookmarksState()) { loadBookmarks(); }

  Future<void> loadBookmarks() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.bookmarks);
      final list = (r.data as List).map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(bookmarks: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> createBookmark(BookmarkModel bm) async {
    try {
      await _api.dio.dio.post(Endpoints.bookmarks, data: bm.toJson());
      await loadBookmarks();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteBookmark(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.bookmarks}/$id');
      await loadBookmarks();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, BookmarksState>((ref) {
  return BookmarksNotifier(ref.watch(apiClientProvider));
});
