import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../domain/project.dart';
import '../domain/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({required ProjectEngineerApi api, required TokenStorage tokenStorage}) : _api = api, _tokenStorage = tokenStorage;
  final ProjectEngineerApi _api;
  final TokenStorage _tokenStorage;

  Future<String> get _token async => await _tokenStorage.read() ?? (throw const ApiException('Your session expired. Please sign in again.'));

  @override
  Future<List<Project>> projects() async => _list(await _api.getProjects(await _token));
  @override
  Future<List<Project>> assignedProjects({String? siteEngineer}) async => _list(await _api.getAssignedProjects(await _token, siteEngineer: siteEngineer));
  @override
  Future<ProjectCounts> counts() async {
    final data = await _api.getProjectCounts(await _token);
    final counts = data['counts'] is Map<String, dynamic> ? data['counts'] as Map<String, dynamic> : data;
    return ProjectCounts.fromJson(counts);
  }
  @override
  Future<void> create({required String projectName, required String title, required String description, required String projectType, required String status}) async {
    await _api.createProject(await _token, projectName: projectName, title: title, description: description, projectType: projectType, status: status);
  }
  @override
  Future<void> update(Project project, {required String projectType, required String status}) async {
    await _api.updateProject(await _token, project.id, projectType: projectType, status: status);
  }
  @override
  Future<void> assign(Project project, {required String siteEngineer}) async {
    await _api.assignProject(await _token, project.id, siteEngineer: siteEngineer);
  }

  @override
  Future<void> approveWorkflow(Project project) async {
    final engineer = project.siteEngineer;
    if (engineer == null || engineer.trim().isEmpty) throw const ApiException('This project has no assigned site engineer.');
    await _api.approveWorkflow(await _token, projectId: project.id, siteEngineer: engineer);
  }

  @override
  Future<void> rejectWorkflow(Project project) async {
    final engineer = project.siteEngineer;
    if (engineer == null || engineer.trim().isEmpty) throw const ApiException('This project has no assigned site engineer.');
    await _api.rejectWorkflow(await _token, projectId: project.id, siteEngineer: engineer);
  }

  List<Project> _list(Map<String, dynamic> response) {
    final raw = response['projects'] ?? response['assignedProjects'] ?? response['assignedprojects'] ?? response['data'] ?? response['results'] ?? const [];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
  }
}
