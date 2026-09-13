import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class VideoModel {
  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final int? width;
  final int? height;
  final int? takenAt;
  final int? createdAt;
  const VideoModel({required this.id, required this.name, this.mimeType, this.size, this.width, this.height, this.takenAt, this.createdAt});
  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
    id: json['id'] as String, name: json['name'] as String? ?? '',
    mimeType: json['mimeType'] as String?, size: json['size'] as int?,
    width: json['width'] as int?, height: json['height'] as int?,
    takenAt: json['takenAt'] as int?, createdAt: json['createdAt'] as int?,
  );
}

class VideosState {
  final List<VideoModel> videos;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  const VideosState({this.videos = const [], this.isLoading = false, this.error, this.searchQuery = ''});
  VideosState copyWith({List<VideoModel>? videos, bool? isLoading, String? error, String? searchQuery}) =>
    VideosState(videos: videos ?? this.videos, isLoading: isLoading ?? this.isLoading, error: error, searchQuery: searchQuery ?? this.searchQuery);
  List<VideoModel> get filtered => searchQuery.isEmpty ? videos : videos.where((v) => v.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
}

class VideosNotifier extends StateNotifier<VideosState> {
  final ApiClient _api;
  VideosNotifier(this._api) : super(const VideosState());

  Future<void> loadVideos() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.videos);
      final data = r.data;
      final list = data is List ? data : (data as Map<String, dynamic>)['items'] as List? ?? [];
      state = state.copyWith(videos: list.map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList(), isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  Future<void> deleteVideo(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.videos}/$id');
      state = state.copyWith(videos: state.videos.where((v) => v.id != id).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> refresh() async => loadVideos();
}

final videosProvider = StateNotifierProvider<VideosNotifier, VideosState>((ref) => VideosNotifier(ref.watch(apiClientProvider)));
