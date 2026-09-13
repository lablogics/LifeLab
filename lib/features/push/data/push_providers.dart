import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../main.dart' show localNotifications;

class PushState {
  final String? token;
  final bool subscribed;
  final bool isLoading;
  final bool foregroundEnabled;
  final bool backgroundEnabled;
  const PushState({this.token, this.subscribed = false, this.isLoading = false, this.foregroundEnabled = true, this.backgroundEnabled = true});
  PushState copyWith({String? token, bool? subscribed, bool? isLoading, bool? foregroundEnabled, bool? backgroundEnabled}) =>
    PushState(token: token ?? this.token, subscribed: subscribed ?? this.subscribed, isLoading: isLoading ?? this.isLoading,
      foregroundEnabled: foregroundEnabled ?? this.foregroundEnabled, backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled);
}

class PushNotifier extends StateNotifier<PushState> {
  final ApiClient _api;
  PushNotifier(this._api) : super(const PushState());

  Future<void> initFcm() async {
    state = state.copyWith(isLoading: true);
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) {
        state = state.copyWith(token: token, isLoading: false);
        await subscribe(token);
      } else {
        state = state.copyWith(isLoading: false);
      }
      messaging.onTokenRefresh.listen((newToken) {
        state = state.copyWith(token: newToken);
        subscribe(newToken);
      });
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    } catch (e) {
      debugPrint('FCM init failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (!state.foregroundEnabled) return;
    final n = message.notification;
    if (n != null) {
      const details = NotificationDetails(android: AndroidNotificationDetails('liflab_default', 'LifeLab Notifications'));
      localNotifications.show(n.hashCode, n.title ?? '', n.body ?? '', details);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null) debugPrint('Navigate to: $route');
  }

  Future<void> subscribe(String token) async {
    try {
      await _api.dio.dio.post(Endpoints.pushSubscribe, data: {'token': token, 'platform': 'android'});
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

  void setForegroundEnabled(bool enabled) => state = state.copyWith(foregroundEnabled: enabled);
  void setBackgroundEnabled(bool enabled) => state = state.copyWith(backgroundEnabled: enabled);
}

final pushProvider = StateNotifierProvider<PushNotifier, PushState>((ref) =>
  PushNotifier(ref.watch(apiClientProvider)));
