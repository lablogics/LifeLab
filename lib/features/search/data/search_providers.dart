import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String type;
  final bool? completed;
  final int? updatedAt;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.completed,
    this.updatedAt,
  });

  factory SearchResult.fromNoteJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      subtitle: json['contentText'] as String?,
      type: 'note',
      updatedAt: json['updatedAt'] as int?,
    );
  }

  factory SearchResult.fromTodoJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      type: 'todo',
      completed: json['completed'] == true || json['completed'] == 1,
    );
  }

  factory SearchResult.fromProjectJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['name'] as String? ?? 'Untitled',
      subtitle: json['description'] as String?,
      type: 'project',
    );
  }
}

class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<SearchResult> get notes => results.where((r) => r.type == 'note').toList();
  List<SearchResult> get todos => results.where((r) => r.type == 'todo').toList();
  List<SearchResult> get projects => results.where((r) => r.type == 'project').toList();
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiClient _api;
  SearchNotifier(this._api) : super(const SearchState());

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.dio.dio.get(
        Endpoints.search,
        queryParameters: {'q': query, 'type': 'all'},
      );
      final data = response.data as Map<String, dynamic>;

      final notes = (data['notes'] as List?)
              ?.map((e) => SearchResult.fromNoteJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final todos = (data['todos'] as List?)
              ?.map((e) => SearchResult.fromTodoJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final projects = (data['projects'] as List?)
              ?.map((e) => SearchResult.fromProjectJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      state = state.copyWith(
        results: [...notes, ...todos, ...projects],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(apiClientProvider));
});
