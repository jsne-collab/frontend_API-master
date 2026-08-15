import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveRole(String role) =>
      _storage.write(key: _roleKey, value: role);

  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }
}
