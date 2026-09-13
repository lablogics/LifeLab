import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class PhotoModel {
  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final int? takenAt;
  const PhotoModel({required this.id, required this.name, this.mimeType, this.size, this.takenAt});
  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(id: json['id'] as String, name: json['name'] as String? ?? '', mimeType: json['mimeType'] as String?, size: json['size'] as int?, takenAt: json['takenAt'] as int?);
}

class PhotosState {
  final List<PhotoModel> photos;
  final bool isLoading;
  final String? error;
  const PhotosState({this.photos = const [], this.isLoading = false, this.error});
  PhotosState copyWith({List<PhotoModel>? photos, bool? isLoading, String? error}) => PhotosState(photos: photos ?? this.photos, isLoading: isLoading ?? this.isLoading, error: error);
}

class PhotosNotifier extends StateNotifier<PhotosState> {
  final ApiClient _api;
  PhotosNotifier(this._api) : super(const PhotosState());

  Future<void> loadPhotos(String storageId) async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.photos, queryParameters: {'storageId': storageId});
      final list = (r.data as List).map((e) => PhotoModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(photos: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}

final photosProvider = StateNotifierProvider<PhotosNotifier, PhotosState>((ref) => PhotosNotifier(ref.watch(apiClientProvider)));

class StoragesState {
  final List<Map<String, dynamic>> storages;
  final bool isLoading;
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
