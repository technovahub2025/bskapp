import 'package:flutter/material.dart';

import '../../estimator/presentation/estimator_home.dart';
import '../../projects/domain/project_repository.dart';
import '../../projects/presentation/project_manager_home.dart';
import '../../site_engineer/presentation/site_engineer_home.dart';
import '../domain/app_role.dart';
import '../domain/auth_repository.dart';
import 'role_selection_screen.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key, required this.role, required this.authRepository, required this.projectRepository});
  final AppRole role;
  final AuthRepository authRepository;
  final ProjectRepository projectRepository;

  Future<void> _signOut(BuildContext context) async {
    await authRepository.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => RoleSelectionScreen(repository: authRepository, projectRepository: projectRepository)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => switch (role) {
        AppRole.projectManager => ProjectManagerHome(repository: projectRepository, onSignOut: () => _signOut(context)),
        AppRole.siteEngineer => SiteEngineerHome(repository: projectRepository, authRepository: authRepository, onSignOut: () => _signOut(context)),
        AppRole.estimator => EstimatorHome(onSignOut: () => _signOut(context)),
      };
}
