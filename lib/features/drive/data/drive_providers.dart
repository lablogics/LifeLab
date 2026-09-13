import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'dart:io';

class DriveItem {
  final String id; final String name; final String type; final String? parentId;
  final int? size; final int? createdAt; final String? url;
  const DriveItem({required this.id, required this.name, required this.type, this.parentId, this.size, this.createdAt, this.url});
  factory DriveItem.fromJson(Map<String, dynamic> json) => DriveItem(
    id: json['id'] as String, name: json['name'] as String? ?? '',
    type: json['type'] as String? ?? 'file', parentId: json['parentId'] as String?,
    size: json['size'] as int?, createdAt: json['createdAt'] as int?,
    url: json['url'] as String?);
}

class DriveState {
  final List<DriveItem> items; final List<String> path; final List<String> pathNames;
  final bool isLoading; final String? error; final bool uploading;
  const DriveState({this.items = const [], this.path = const [], this.pathNames = const [], this.isLoading = false, this.error, this.uploading = false});
  DriveState copyWith({List<DriveItem>? items, List<String>? path, List<String>? pathNames, bool? isLoading, String? error, bool? uploading}) =>
    DriveState(items: items ?? this.items, path: path ?? this.path, pathNames: pathNames ?? this.pathNames, isLoading: isLoading ?? this.isLoading, error: error, uploading: uploading ?? this.uploading);
}

class DriveNotifier extends StateNotifier<DriveState> {
  final ApiClient _api;
  String? _storageId;
  DriveNotifier(this._api) : super(const DriveState());

  void setStorage(String storageId) { _storageId = storageId; loadFolder(null, ''); }

  Future<void> loadFolder(String? parentId, String name) async {
    if (_storageId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{'storageId': _storageId};
      if (parentId != null) params['parentId'] = parentId;
      final r = await _api.dio.dio.get(Endpoints.drive, queryParameters: params);
      final list = (r.data as List).map((e) => DriveItem.fromJson(e as Map<String, dynamic>)).toList();
      final newPath = parentId == null ? <String>[] : [...state.path, parentId];
      final newPathNames = parentId == null ? <String>[] : [...state.pathNames, name];
      state = state.copyWith(items: list, path: newPath, pathNames: newPathNames, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  void goBack() {
    if (state.path.isEmpty) return;
    final newPath = List<String>.from(state.path)..removeLast();
    final newPathNames = List<String>.from(state.pathNames)..removeLast();
    loadFolder(newPath.isEmpty ? null : newPath.last, '');
  }

  Future<void> createFolder(String name) async {
    if (_storageId == null) return;
    try {
      await _api.dio.dio.post(Endpoints.drive, data: {'storageId': _storageId, 'name': name, 'type': 'folder', if (state.path.isNotEmpty) 'parentId': state.path.last});
      loadFolder(state.path.isEmpty ? null : state.path.last, '');
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> renameItem(String id, String name) async {
    try {
      await _api.dio.dio.put('${Endpoints.drive}/$id', data: {'name': name});
      loadFolder(state.path.isEmpty ? null : state.path.last, '');
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.drive}/$id');
      state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> uploadFile(String filePath) async {
    if (_storageId == null) return;
    state = state.copyWith(uploading: true);
    try {
      final file = File(filePath);
      final formData = {
        'file': await file.length().then((_) => MultipartFile.fromFile(filePath, filename: file.path.split('/').last)),
        'storageId': _storageId,
        if (state.path.isNotEmpty) 'parentId': state.path.last,
      };
      await _api.dio.dio.post(Endpoints.drive, data: formData);
      state = state.copyWith(uploading: false);
      loadFolder(state.path.isEmpty ? null : state.path.last, '');
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
    }
  }

  Future<String?> getDownloadUrl(String id) async {
    try {
      final r = await _api.dio.dio.get('${Endpoints.drive}/$id');
      return r.data['url'] as String?;
    } catch (_) { return null; }
  }

  Future<void> refresh() async => loadFolder(state.path.isEmpty ? null : state.path.last, '');
}

final driveProvider = StateNotifierProvider<DriveNotifier, DriveState>((ref) => DriveNotifier(ref.watch(apiClientProvider)));
