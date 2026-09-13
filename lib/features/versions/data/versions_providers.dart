import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class NoteVersion {
  final String id; final String noteId; final String? title; final String? contentJson; final int? createdAt;
  const NoteVersion({required this.id, required this.noteId, this.title, this.contentJson, this.createdAt});
  factory NoteVersion.fromJson(Map<String, dynamic> json) => NoteVersion(
    id: json['id'] as String, noteId: json['noteId'] as String? ?? '',
    title: json['title'] as String?, contentJson: json['contentJson'] as String?,
    createdAt: json['createdAt'] as int?);
}

class VersionsState { final List<NoteVersion> versions; final bool isLoading;
  const VersionsState({this.versions = const [], this.isLoading = false});
  VersionsState copyWith({List<NoteVersion>? versions, bool? isLoading}) => VersionsState(versions: versions ?? this.versions, isLoading: isLoading ?? this.isLoading); }

class VersionsNotifier extends StateNotifier<VersionsState> {
  final ApiClient _api;
  VersionsNotifier(this._api) : super(const VersionsState());
  Future<void> loadVersions(String noteId) async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get('${Endpoints.versions}/$noteId');
      final list = (r.data as List? ?? []).map((e) => NoteVersion.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(versions: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }
  Future<bool> restoreVersion(String noteId, String versionId) async {
    try {
      await _api.dio.dio.post('${Endpoints.versions}/$noteId/restore/$versionId');
      return true;
    } catch (_) { return false; }
  }
}

final versionsProvider = StateNotifierProvider<VersionsNotifier, VersionsState>((ref) => VersionsNotifier(ref.watch(apiClientProvider)));
