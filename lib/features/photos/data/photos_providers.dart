import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'dart:io';

class PhotoModel {
  final String id; final String name; final String? mimeType; final int? size;
  final int? takenAt; final bool starred; final bool favorite; final bool trashed;
  final int? width; final int? height; final String? cameraModel;
  final double? latitude; final double? longitude;
  const PhotoModel({required this.id, required this.name, this.mimeType, this.size, this.takenAt,
    this.starred = false, this.favorite = false, this.trashed = false,
    this.width, this.height, this.cameraModel, this.latitude, this.longitude});
  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'] as String, name: json['name'] as String? ?? '',
    mimeType: json['mimeType'] as String?, size: json['size'] as int?,
    takenAt: json['takenAt'] as int?, starred: json['starred'] as bool? ?? false,
    favorite: json['favorite'] as bool? ?? false, trashed: json['trashed'] as bool? ?? false,
    width: json['width'] as int?, height: json['height'] as int?,
    cameraModel: json['cameraModel'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(), longitude: (json['longitude'] as num?)?.toDouble());
}

enum PhotosView { all, starred, favorites, trash }

class PhotosState {
  final List<PhotoModel> photos; final bool isLoading; final String? error;
  final PhotosView view; final String searchQuery; final bool uploading;
  const PhotosState({this.photos = const [], this.isLoading = false, this.error, this.view = PhotosView.all, this.searchQuery = '', this.uploading = false});
  PhotosState copyWith({List<PhotoModel>? photos, bool? isLoading, String? error, PhotosView? view, String? searchQuery, bool? uploading}) =>
    PhotosState(photos: photos ?? this.photos, isLoading: isLoading ?? this.isLoading, error: error, view: view ?? this.view, searchQuery: searchQuery ?? this.searchQuery, uploading: uploading ?? this.uploading);
  List<PhotoModel> get filtered => searchQuery.isEmpty ? photos : photos.where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
}

class PhotosNotifier extends StateNotifier<PhotosState> {
  final ApiClient _api;
  PhotosNotifier(this._api) : super(const PhotosState());

  Future<void> loadPhotos({String? storageId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{};
      if (storageId != null) params['storageId'] = storageId;
      final endpoint = state.view == PhotosView.starred ? Endpoints.photosStarred : Endpoints.photos;
      final r = await _api.dio.dio.get(endpoint, queryParameters: params.isNotEmpty ? params : null);
      final data = r.data;
      final list = data is List ? data : (data as Map<String, dynamic>)['items'] as List? ?? [];
      state = state.copyWith(photos: list.map((e) => PhotoModel.fromJson(e as Map<String, dynamic>)).toList(), isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> searchPhotos(String query) async {
    if (query.isEmpty) { loadPhotos(); return; }
    state = state.copyWith(isLoading: true, searchQuery: query);
    try {
      final r = await _api.dio.dio.get(Endpoints.photosSearch, queryParameters: {'q': query});
      final list = ((r.data as Map<String, dynamic>)['items'] as List? ?? []).map((e) => PhotoModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(photos: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  void setView(PhotosView view) { state = state.copyWith(view: view, searchQuery: ''); loadPhotos(); }
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  Future<void> refresh() async => loadPhotos();

  Future<void> toggleStar(String id) async {
    try {
      await _api.dio.dio.post('${Endpoints.photos}/$id/star');
      state = state.copyWith(photos: state.photos.map((p) => p.id == id ? PhotoModel(id: p.id, name: p.name, mimeType: p.mimeType, size: p.size, takenAt: p.takenAt, starred: !p.starred, favorite: p.favorite, width: p.width, height: p.height, cameraModel: p.cameraModel, latitude: p.latitude, longitude: p.longitude) : p).toList());
    } catch (_) {}
  }

  Future<void> trashPhoto(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.photos}/$id');
      state = state.copyWith(photos: state.photos.where((p) => p.id != id).toList());
    } catch (_) {}
  }

  Future<void> uploadPhoto(String filePath, {String? storageId}) async {
    state = state.copyWith(uploading: true);
    try {
      final file = File(filePath);
      final formData = {
        'file': await file.length().then((len) => MultipartFile.fromFile(filePath, filename: file.path.split('/').last)),
        if (storageId != null) 'storageId': storageId,
      };
      await _api.dio.dio.post(Endpoints.photos, data: formData);
      state = state.copyWith(uploading: false);
      loadPhotos();
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
    }
  }

  Future<void> restorePhoto(String id) async {
    try {
      await _api.dio.dio.post('${Endpoints.photos}/$id/restore');
      loadPhotos();
    } catch (_) {}
  }
}

final photosProvider = StateNotifierProvider<PhotosNotifier, PhotosState>((ref) => PhotosNotifier(ref.watch(apiClientProvider)));

class StoragesState {
  final List<Map<String, dynamic>> storages; final bool isLoading;
  const StoragesState({this.storages = const [], this.isLoading = false});
  StoragesState copyWith({List<Map<String, dynamic>>? storages, bool? isLoading}) => StoragesState(storages: storages ?? this.storages, isLoading: isLoading ?? this.isLoading);
}

class StoragesNotifier extends StateNotifier<StoragesState> {
  final ApiClient _api;
  StoragesNotifier(this._api) : super(const StoragesState()) { loadStorages(); }
  Future<void> loadStorages() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.storages);
      final list = (r.data as List).cast<Map<String, dynamic>>();
      state = state.copyWith(storages: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }
}

final storagesProvider = StateNotifierProvider<StoragesNotifier, StoragesState>((ref) => StoragesNotifier(ref.watch(apiClientProvider)));
