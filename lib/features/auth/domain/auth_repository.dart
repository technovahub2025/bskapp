import 'app_role.dart';

abstract interface class AuthRepository {
  Future<String?> readToken();
  Future<void> login({required AppRole role, required String name, required String password});
  Future<String?> readEngineerName();
  Future<void> logout();
}
