import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class AttachmentModel {
  final String id; final String noteId; final String fileName; final String? mimeType; final int? size; final int? createdAt;
  const AttachmentModel({required this.id, required this.noteId, required this.fileName, this.mimeType, this.size, this.createdAt});
  factory AttachmentModel.fromJson(Map<String, dynamic> json) => AttachmentModel(
    id: json['id'] as String, noteId: json['noteId'] as String? ?? '',
    fileName: json['fileName'] as String? ?? json['name'] as String? ?? '',
    mimeType: json['mimeType'] as String?, size: json['size'] as int?,
    createdAt: json['createdAt'] as int?);
}

class AttachmentsState { final List<AttachmentModel> attachments; final bool isLoading;
  const AttachmentsState({this.attachments = const [], this.isLoading = false});
  AttachmentsState copyWith({List<AttachmentModel>? attachments, bool? isLoading}) => AttachmentsState(attachments: attachments ?? this.attachments, isLoading: isLoading ?? this.isLoading); }

class AttachmentsNotifier extends StateNotifier<AttachmentsState> {
  final ApiClient _api;
  AttachmentsNotifier(this._api) : super(const AttachmentsState());
  Future<void> loadAttachments(String noteId) async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get('${Endpoints.attachments}/$noteId');
      final list = (r.data as List? ?? []).map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(attachments: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }
  Future<bool> deleteAttachment(String id) async {
    try { await _api.dio.dio.delete('${Endpoints.attachments}/$id'); return true; } catch (_) { return false; }
  }
}

final attachmentsProvider = StateNotifierProvider<AttachmentsNotifier, AttachmentsState>((ref) => AttachmentsNotifier(ref.watch(apiClientProvider)));
