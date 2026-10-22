import 'project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> projects();
  Future<List<Project>> assignedProjects({String? siteEngineer});
  Future<ProjectCounts> counts();
  Future<void> create({required String projectName, required String title, required String description});
  Future<void> update(Project project, {required String title, required String description});
  Future<void> assign(Project project, {required String siteEngineer});
  Future<void> approveWorkflow(Project project);
  Future<void> rejectWorkflow(Project project);
}
