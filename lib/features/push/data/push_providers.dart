import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class PushState {
  final String? token;
  final bool subscribed;
  final bool isLoading;
  const PushState({this.token, this.subscribed = false, this.isLoading = false});
  PushState copyWith({String? token, bool? subscribed, bool? isLoading}) =>
    PushState(token: token ?? this.token, subscribed: subscribed ?? this.subscribed, isLoading: isLoading ?? this.isLoading);
}

class PushNotifier extends StateNotifier<PushState> {
  final ApiClient _api;
  PushNotifier(this._api) : super(const PushState());

  Future<void> initFcm() async {
    // Firebase initialization would happen in main.dart
    // This is a placeholder for FCM token retrieval
    state = state.copyWith(isLoading: true);
    try {
      // In real implementation:
      // final token = await FirebaseMessaging.instance.getToken();
      // state = state.copyWith(token: token, isLoading: false);
      // await subscribe(token!);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> subscribe(String token) async {
    try {
      await _api.dio.dio.post(Endpoints.pushSubscribe, data: {
        'token': token,
        'platform': 'android',
      });
      state = state.copyWith(subscribed: true);
    } catch (_) {}
  }

  Future<void> unsubscribe() async {
    if (state.token == null) return;
    try {
      await _api.dio.dio.delete(Endpoints.pushSubscribe, data: {'token': state.token});
      state = state.copyWith(subscribed: false);
    } catch (_) {}
  }
}

final pushProvider = StateNotifierProvider<PushNotifier, PushState>((ref) =>
  PushNotifier(ref.watch(apiClientProvider)));
