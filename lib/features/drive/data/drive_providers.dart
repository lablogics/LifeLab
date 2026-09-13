import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class DriveItem {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final int? size;
  const DriveItem({required this.id, required this.name, required this.type, this.parentId, this.size});
  factory DriveItem.fromJson(Map<String, dynamic> json) => DriveItem(id: json['id'] as String, name: json['name'] as String? ?? '', type: json['type'] as String? ?? 'file', parentId: json['parentId'] as String?, size: json['size'] as int?);
}

class DriveState {
  final List<DriveItem> items;
  final List<String> path;
  final bool isLoading;
  const DriveState({this.items = const [], this.path = const [], this.isLoading = false});
  DriveState copyWith({List<DriveItem>? items, List<String>? path, bool? isLoading}) => DriveState(items: items ?? this.items, path: path ?? this.path, isLoading: isLoading ?? this.isLoading);
}

class DriveNotifier extends StateNotifier<DriveState> {
  final ApiClient _api;
  String? _storageId;
  DriveNotifier(this._api) : super(const DriveState());

  void setStorage(String storageId) { _storageId = storageId; loadFolder(null); }

  Future<void> loadFolder(String? parentId) async {
    if (_storageId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{'storageId': _storageId};
      if (parentId != null) params['parentId'] = parentId;
      final r = await _api.dio.dio.get(Endpoints.drive, queryParameters: params);
      final list = (r.data as List).map((e) => DriveItem.fromJson(e as Map<String, dynamic>)).toList();
      final newPath = parentId == null ? <String>[] : [...state.path, parentId];
      state = state.copyWith(items: list, path: newPath, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }

  void goBack() {
    if (state.path.isEmpty) return;
    final newPath = List<String>.from(state.path)..removeLast();
    loadFolder(newPath.isEmpty ? null : newPath.last);
  }
}

final driveProvider = StateNotifierProvider<DriveNotifier, DriveState>((ref) => DriveNotifier(ref.watch(apiClientProvider)));
