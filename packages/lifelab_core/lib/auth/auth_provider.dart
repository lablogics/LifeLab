import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    final session = await _repository.getSession();
    state = session != null
        ? AuthState.authenticated(userId: 'unknown')
        : AuthState.unauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = AuthState.authenticating();
    try {
      final result = await _repository.login(email, password);
      if (result['needs2FA'] == true) {
        state = AuthState.needs2FA();
      } else {
        state = AuthState.authenticated(userId: result['userId'] as String? ?? 'unknown', email: email);
      }
    } catch (e) {
      state = AuthState.unauthenticated().copyWith(error: e.toString());
    }
  }

  Future<void> verify2FA(String code) async {
    try {
      await _repository.verify2FA(code);
      state = AuthState.authenticated(userId: 'unknown');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }
}
