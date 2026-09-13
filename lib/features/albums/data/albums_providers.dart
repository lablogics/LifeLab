import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class AlbumModel {
  final String id;
  final String name;
  final int? photoCount;
  final String? coverUrl;
  final int? createdAt;
  const AlbumModel({required this.id, required this.name, this.photoCount, this.coverUrl, this.createdAt});
  factory AlbumModel.fromJson(Map<String, dynamic> json) => AlbumModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    photoCount: json['photoCount'] as int?,
    coverUrl: json['coverUrl'] as String?,
    createdAt: json['createdAt'] as int?);
}

class AlbumsState {
  final List<AlbumModel> albums;
  final bool isLoading;
  final String? error;
  const AlbumsState({this.albums = const [], this.isLoading = false, this.error});
  AlbumsState copyWith({List<AlbumModel>? albums, bool? isLoading, String? error}) =>
    AlbumsState(albums: albums ?? this.albums, isLoading: isLoading ?? this.isLoading, error: error);
}

class AlbumsNotifier extends StateNotifier<AlbumsState> {
  final ApiClient _api;
  AlbumsNotifier(this._api) : super(const AlbumsState());

  Future<void> loadAlbums() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get('${Endpoints.photos}/albums');
      final list = (r.data as List? ?? []).map((e) => AlbumModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(albums: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createAlbum(String name) async {
    try {
      await _api.dio.dio.post('${Endpoints.photos}/albums', data: {'name': name});
      loadAlbums();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameAlbum(String id, String name) async {
    try {
      await _api.dio.dio.put('${Endpoints.photos}/albums/$id', data: {'name': name});
      loadAlbums();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAlbum(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.photos}/albums/$id');
      state = state.copyWith(albums: state.albums.where((a) => a.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds) async {
    try {
      await _api.dio.dio.post('${Endpoints.photos}/albums/$albumId/photos', data: {'photoIds': photoIds});
    } catch (_) {}
  }

  Future<void> removePhotoFromAlbum(String albumId, String photoId) async {
    try {
      await _api.dio.dio.delete('${Endpoints.photos}/albums/$albumId/photos/$photoId');
    } catch (_) {}
  }

  Future<void> refresh() async => loadAlbums();
}

final albumsProvider = StateNotifierProvider<AlbumsNotifier, AlbumsState>((ref) =>
  AlbumsNotifier(ref.watch(apiClientProvider)));
