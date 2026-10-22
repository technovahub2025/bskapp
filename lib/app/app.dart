import 'package:flutter/material.dart';

import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/project_engineer_api.dart';
import '../features/auth/data/token_storage.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/projects/data/project_repository_impl.dart';
import 'app_theme.dart';

class BskApp extends StatelessWidget {
  const BskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ProjectEngineerApi();
    final tokenStorage = TokenStorage();
    final repository = AuthRepositoryImpl(
      api: api,
      tokenStorage: tokenStorage,
    );
    final projectRepository = ProjectRepositoryImpl(api: api, tokenStorage: tokenStorage);
    return MaterialApp(
      title: 'BuildSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashScreen(repository: repository, projectRepository: projectRepository),
    );
  }
}
