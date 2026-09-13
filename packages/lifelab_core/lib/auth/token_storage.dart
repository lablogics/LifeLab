abstract class TokenStorage {
  Future<void> saveSession(String sessionToken);
  Future<String?> getSession();
  Future<void> clearSession();
}
