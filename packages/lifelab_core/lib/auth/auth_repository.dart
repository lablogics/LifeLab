import '../api/api_client.dart';
import '../api/endpoints.dart';
import 'token_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRepository({required this.apiClient, required this.tokenStorage});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.dio.dio.post(
      Endpoints.login, data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['sessionToken'] != null) {
      await tokenStorage.saveSession(data['sessionToken'] as String);
    }
    return data;
  }

  Future<void> verify2FA(String code) async {
    await apiClient.dio.dio.post(Endpoints.twoFaVerify, data: {'code': code});
  }

  Future<void> logout() async {
    await apiClient.dio.dio.post(Endpoints.logout);
    await tokenStorage.clearSession();
  }

  Future<String?> getSession() => tokenStorage.getSession();
}
