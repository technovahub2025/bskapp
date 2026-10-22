class Project {
  const Project({required this.id, required this.title, required this.description, this.projectName = '', this.siteEngineer});
  final String id;
  final String title;
  final String description;
  final String projectName;
  final String? siteEngineer;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        projectName: (json['projectname'] ?? json['projectName'] ?? '').toString(),
        siteEngineer: json['siteEngineer']?.toString(),
      );
}

class ProjectCounts {
  const ProjectCounts({this.total = 0, this.assigned = 0, this.unassigned = 0});
  final int total;
  final int assigned;
  final int unassigned;

  factory ProjectCounts.fromJson(Map<String, dynamic> json) => ProjectCounts(
        total: _int(json['total'] ?? json['totalProjects']),
        assigned: _int(json['assigned'] ?? json['assignedProjects']),
        unassigned: _int(json['unassigned'] ?? json['unassignedProjects']),
      );
}

int _int(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
