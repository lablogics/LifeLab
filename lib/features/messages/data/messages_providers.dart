import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'models/message_model.dart';

class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const MessagesState({this.messages = const [], this.isLoading = false, this.error});

  MessagesState copyWith({List<MessageModel>? messages, bool? isLoading, String? error}) {
    return MessagesState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiClient _api;
  MessagesNotifier(this._api) : super(const MessagesState());

  Future<void> loadMessages(String contactId) async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.messages, queryParameters: {'contactId': contactId});
      final list = (r.data as List).map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(messages: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> sendMessage(String contactId, String content, String direction) async {
    try {
      await _api.dio.dio.post(Endpoints.messages, data: {'contactId': contactId, 'content': content, 'direction': direction});
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteMessage(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.messages}/$id');
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }
}

final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  return MessagesNotifier(ref.watch(apiClientProvider));
});
