import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../../projects/domain/project.dart';

class EstimatorRepository {
  EstimatorRepository({required ProjectEngineerApi api, required TokenStorage tokenStorage}) : _api = api, _tokenStorage = tokenStorage;
  final ProjectEngineerApi _api;
  final TokenStorage _tokenStorage;

  Future<String> get _token async => await _tokenStorage.read() ?? (throw const ApiException('Your session expired. Please sign in again.'));

  Future<List<Project>> projects() async => _projectList(await _api.getEstimatorProjects(await _token));
  Future<List<Project>> assignedProjects({String? siteEngineer}) async => _projectList(await _api.getAssignedProjects(await _token, siteEngineer: siteEngineer));

  Future<List<Map<String, dynamic>>> reports(String type, String projectId) async {
    final token = await _token;
    final response = switch (type) {
      'measurement' => await _api.getMeasurements(token, projectId: projectId),
      'labour' => await _api.getLabourReports(token, projectId: projectId),
      _ => await _api.getMaterialReports(token, projectId: projectId),
    };
    return _records(response);
  }

  Future<Map<String, dynamic>> preview(String projectId, String siteEngineer) async => _api.workflowPreview(await _token, projectId: projectId, siteEngineer: siteEngineer);

  List<Project> _projectList(Map<String, dynamic> response) {
    final raw = response['projects'] ?? response['data'] ?? response['results'] ?? const [];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
  }

  List<Map<String, dynamic>> _records(Map<String, dynamic> response) {
    final raw = response['reports'] ?? response['data'] ?? response['results'] ?? response['measurements'] ?? response['measurementReports'] ?? response['measurementReport'] ?? response['labours'] ?? response['labourReports'] ?? response['labourReport'] ?? response['materials'] ?? response['materialReports'] ?? response['materialReport'] ?? const [];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return const [];
  }
}
