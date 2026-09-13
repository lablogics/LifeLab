import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'session_token';

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveSession(String sessionToken) async {
    await _storage.write(key: _sessionKey, value: sessionToken);
  }

  @override
  Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
