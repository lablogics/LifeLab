enum AuthStatus { initial, unauthenticated, authenticating, needs2FA, authenticated, expired }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? name;
  final String? error;

  AuthState({required this.status, this.userId, this.email, this.name, this.error});

  factory AuthState.initial() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.authenticating() => AuthState(status: AuthStatus.authenticating);
  factory AuthState.needs2FA() => AuthState(status: AuthStatus.needs2FA);
  factory AuthState.authenticated({String? userId, String? email, String? name}) =>
      AuthState(status: AuthStatus.authenticated, userId: userId, email: email, name: name);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.expired() => AuthState(status: AuthStatus.expired);

  AuthState copyWith({AuthStatus? status, String? userId, String? email, String? name, String? error}) {
    return AuthState(
      status: status ?? this.status, userId: userId ?? this.userId,
      email: email ?? this.email, name: name ?? this.name, error: error ?? this.error,
    );
  }
}
