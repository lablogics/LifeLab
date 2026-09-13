import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'models/password_model.dart';

class PasswordsState {
  final List<PasswordModel> passwords;
  final bool isLoading;
  final String? error;

  const PasswordsState({this.passwords = const [], this.isLoading = false, this.error});

  PasswordsState copyWith({List<PasswordModel>? passwords, bool? isLoading, String? error}) {
    return PasswordsState(passwords: passwords ?? this.passwords, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class PasswordsNotifier extends StateNotifier<PasswordsState> {
  final ApiClient _api;
  PasswordsNotifier(this._api) : super(const PasswordsState()) { loadPasswords(); }

  Future<void> loadPasswords() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.passwords);
      final list = (r.data as List).map((e) => PasswordModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(passwords: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> createPassword(PasswordModel pw) async {
    try {
      await _api.dio.dio.post(Endpoints.passwords, data: pw.toJson());
      await loadPasswords();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> updatePassword(PasswordModel pw) async {
    try {
      await _api.dio.dio.put('${Endpoints.passwords}/${pw.id}', data: pw.toJson());
      await loadPasswords();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deletePassword(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.passwords}/$id');
      await loadPasswords();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }
}

final passwordsProvider = StateNotifierProvider<PasswordsNotifier, PasswordsState>((ref) {
  return PasswordsNotifier(ref.watch(apiClientProvider));
});
