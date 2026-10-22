import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/auth_repository.dart';
import '../../projects/domain/project_repository.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.repository, required this.projectRepository});
  final AuthRepository repository;
  final ProjectRepository projectRepository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_continue());
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final token = await widget.repository.readToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => RoleSelectionScreen(repository: widget.repository, projectRepository: widget.projectRepository, hasSession: token != null),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.navy,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 86, height: 86, decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(26)), child: const Icon(Icons.apartment_rounded, color: AppTheme.navy, size: 45)),
            const SizedBox(height: 20),
            const Text('BUILDSPHERE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text('Build better, together.', style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 14)),
            const SizedBox(height: 36),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.yellow)),
          ]),
        ),
      );
}
