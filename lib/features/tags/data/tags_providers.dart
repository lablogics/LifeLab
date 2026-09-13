import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import '../../notes/data/models/tag_model.dart';

class TagsState {
  final List<TagModel> tags;
  final bool isLoading;
  final String? error;
  const TagsState({this.tags = const [], this.isLoading = false, this.error});
  TagsState copyWith({List<TagModel>? tags, bool? isLoading, String? error}) =>
    TagsState(tags: tags ?? this.tags, isLoading: isLoading ?? this.isLoading, error: error);
}

class TagsNotifier extends StateNotifier<TagsState> {
  final ApiClient _api;
  TagsNotifier(this._api) : super(const TagsState());

  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.tags);
      final list = (r.data as List).map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(tags: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> createTag(String name, String color) async {
    try {
      final r = await _api.dio.dio.post(Endpoints.tags, data: {'name': name, 'color': color});
      final tag = TagModel.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(tags: [...state.tags, tag]);
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> renameTag(String id, String name) async {
    try {
      await _api.dio.dio.put('${Endpoints.tags}/$id', data: {'name': name});
      state = state.copyWith(tags: state.tags.map((t) => t.id == id ? t.copyWith(name: name) : t).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> updateTagColor(String id, String color) async {
    try {
      await _api.dio.dio.put('${Endpoints.tags}/$id', data: {'color': color});
      state = state.copyWith(tags: state.tags.map((t) => t.id == id ? t.copyWith(color: color) : t).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.tags}/$id');
      state = state.copyWith(tags: state.tags.where((t) => t.id != id).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> refresh() async => loadTags();
}

final tagsProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) => TagsNotifier(ref.watch(apiClientProvider)));
