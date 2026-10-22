import 'package:flutter/material.dart';

import '../../projects/domain/project_repository.dart';
import 'projects_screen.dart';

class ProjectManagerHome extends StatelessWidget {
  const ProjectManagerHome({super.key, required this.repository, required this.onSignOut});
  final ProjectRepository repository;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Project Manager workspace'), actions: [IconButton(tooltip: 'Sign out', onPressed: onSignOut, icon: const Icon(Icons.logout_rounded))]),
        body: ProjectsScreen(repository: repository),
      );
}
