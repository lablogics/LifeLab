import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../auth/token_storage.dart';
import '../auth/secure_token_storage.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
