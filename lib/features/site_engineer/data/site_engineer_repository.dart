import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_repository.dart';

class SiteEngineerRepository {
  SiteEngineerRepository({required ProjectEngineerApi api, required TokenStorage tokenStorage, required ProjectRepository projects})
      : _api = api, _tokenStorage = tokenStorage, _projects = projects;
  final ProjectEngineerApi _api;
  final TokenStorage _tokenStorage;
  final ProjectRepository _projects;

  Future<String> get _token async => await _tokenStorage.read() ?? (throw const ApiException('Your session expired. Please sign in again.'));
  Future<List<Project>> assignedProjects(String name) => _projects.assignedProjects(siteEngineer: name);

  Future<List<Map<String, dynamic>>> reports(String type, {required String projectId, required String name}) async {
    final token = await _token;
    final response = switch (type) {
      'measurement' => await _api.getMeasurements(token, projectId: projectId, siteEngineer: name),
      'labour' => await _api.getLabourReports(token, projectId: projectId, siteEngineer: name),
      _ => await _api.getMaterialReports(token, projectId: projectId, siteEngineer: name),
    };
    return _records(response);
  }

  Future<void> createReport(String type, {required String projectId, required String name, required Map<String, dynamic> entry}) async {
    final token = await _token;
    final key = switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
    final body = {'projectId': projectId, 'siteEngineer': name, key: [entry]};
    switch (type) {
      case 'measurement': await _api.createMeasurement(token, body);
      case 'labour': await _api.createLabour(token, body);
      default: await _api.createMaterial(token, body);
    }
  }

  Future<void> updateReport(String type, String id, Map<String, dynamic> fields) async {
    final token = await _token;
    switch (type) {
      case 'measurement': await _api.updateMeasurement(token, id, fields);
      case 'labour': await _api.updateLabour(token, id, fields);
      default: await _api.updateMaterial(token, id, fields);
    }
  }

  Future<Map<String, dynamic>> preview({required String projectId, required String name}) async => _api.workflowPreview(await _token, projectId: projectId, siteEngineer: name);
  Future<void> submit({required String projectId, required String name}) async {
    await _api.submitWorkflow(await _token, projectId: projectId, siteEngineer: name);
  }
  Future<void> submitIssue(String issueText, {required String projectId, required String siteEngineer, List<String> images = const []}) async =>
      _api.submitIssue(await _token, projectId: projectId, siteEngineer: siteEngineer, issueText: issueText, images: images);
  Future<List<Map<String, dynamic>>> issues({required String projectId, required String siteEngineer}) async {
    final records = _records(await _api.getIssues(await _token, projectId: projectId, siteEngineer: siteEngineer));
    return records.where((issue) {
      final rawId = issue['projectId'] ?? issue['projectid'] ?? (issue['project'] is Map ? (issue['project'] as Map)['_id'] ?? (issue['project'] as Map)['id'] : null);
      final linkedProjectId = rawId is Map ? (rawId['_id'] ?? rawId['id'])?.toString() : rawId?.toString();
      final owner = (issue['siteEngineer'] ?? issue['siteengineer'] ?? issue['submittedBy'] ?? issue['createdBy'])?.toString().trim().toLowerCase();
      return linkedProjectId == projectId && owner == siteEngineer.trim().toLowerCase();
    }).toList();
  }

  List<Map<String, dynamic>> _records(Map<String, dynamic> response) {
    var payload = response;
    for (var depth = 0; depth < 3; depth++) {
      final nested = payload['data'] ?? payload['result'];
      if (nested is! Map) break;
      payload = {...payload, ...Map<String, dynamic>.from(nested)};
    }
    final raw = payload['reports'] ??
        payload['issues'] ??
        payload['issue'] ??
        payload['issueReports'] ??
        payload['results'] ??
        payload['data'] ??
        response['measurements'] ??
        response['measurementReports'] ??
        response['measurementReport'] ??
        response['labours'] ??
        response['labourReports'] ??
        response['labourReport'] ??
        response['materials'] ??
        response['materialReports'] ??
        response['materialReport'] ??
        const [];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) return [raw];
    return const [];
  }
}
