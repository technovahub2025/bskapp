import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'auth_token';
  static const _engineerNameKey = 'site_engineer_name';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> writeEngineerName(String name) => _storage.write(key: _engineerNameKey, value: name);
  Future<String?> readEngineerName() => _storage.read(key: _engineerNameKey);
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _engineerNameKey);
  }
}
