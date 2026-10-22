import '../domain/app_role.dart';
import '../domain/auth_repository.dart';
import 'project_engineer_api.dart';
import 'token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required ProjectEngineerApi api, required TokenStorage tokenStorage}) : _api = api, _tokenStorage = tokenStorage;
  final ProjectEngineerApi _api;
  final TokenStorage _tokenStorage;

  @override
  Future<String?> readToken() => _tokenStorage.read();

  @override
  Future<String?> readEngineerName() => _tokenStorage.readEngineerName();

  @override
  Future<void> login({required AppRole role, required String name, required String password}) async {
    if (role == AppRole.siteEngineer) {
      final result = await _api.siteEngineerLogin(name: name, password: password);
      await _tokenStorage.write(result['token'] as String);
      await _tokenStorage.writeEngineerName(name);
      return;
    }
    if (role == AppRole.estimator) {
      final token = await _api.estimatorLogin(phone: name, password: password);
      await _tokenStorage.write(token);
      return;
    }
    if (role != AppRole.projectManager) throw const ApiException('Sign-in for this role is not available yet.');
    final token = await _api.login(phone: name, password: password);
    await _tokenStorage.write(token);
  }

  @override
  Future<void> logout() => _tokenStorage.clear();
}
