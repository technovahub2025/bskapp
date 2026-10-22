import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/app_role.dart';
import '../domain/auth_repository.dart';
import '../../projects/domain/project_repository.dart';
import 'sign_in_screen.dart';
import 'role_home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.repository, required this.projectRepository, this.hasSession = false});
  final AuthRepository repository;
  final ProjectRepository projectRepository;
  final bool hasSession;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  AppRole _selected = AppRole.projectManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight - 44), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.apartment_rounded, color: AppTheme.blue)),
            const SizedBox(width: 11), const Text('BuildSphere', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          ]),
          const SizedBox(height: 42),
          const Text('Welcome aboard', style: TextStyle(color: AppTheme.blue, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          const Text('How will you\nwork today?', style: TextStyle(color: AppTheme.navy, fontSize: 32, height: 1.16, fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 10),
          Text('Choose your role to get started.', style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600)),
          const SizedBox(height: 26),
          ...AppRole.values.map(_roleCard),
          const SizedBox(height: 10),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, height: 56, child: FilledButton(
            onPressed: () {
              if (widget.hasSession && _selected == AppRole.projectManager) {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoleHomeScreen(role: _selected, authRepository: widget.repository, projectRepository: widget.projectRepository)));
              } else {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SignInScreen(role: _selected, repository: widget.repository, projectRepository: widget.projectRepository)));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(widget.hasSession && _selected == AppRole.projectManager ? 'Continue to dashboard' : 'Continue as ${_selected.label}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(width: 9), const Icon(Icons.arrow_forward_rounded, size: 19)]),
          )),
          const SizedBox(height: 15),
          Center(child: Text('SECURE ACCESS  •  BUILT FOR YOUR TEAM', style: TextStyle(fontSize: 10, letterSpacing: 1.05, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade400))),
        ])),
      ))),
    );
  }

  Widget _roleCard(AppRole role) {
    final selected = role == _selected;
    final icon = switch (role) { AppRole.projectManager => Icons.domain_rounded, AppRole.siteEngineer => Icons.engineering_rounded, AppRole.estimator => Icons.calculate_outlined, AppRole.contractor => Icons.handyman_rounded };
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(
      borderRadius: BorderRadius.circular(17), onTap: () => setState(() => _selected = role),
      child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? AppTheme.blue.withValues(alpha: .055) : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: selected ? AppTheme.blue : const Color(0xFFE5EAF1), width: selected ? 1.6 : 1)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: selected ? AppTheme.blue.withValues(alpha: .12) : const Color(0xFFF1F4F8), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: selected ? AppTheme.blue : AppTheme.navy, size: 25)),
          const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(role.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.navy)), const SizedBox(height: 4), Text(role.description, style: TextStyle(fontSize: 12.5, color: Colors.blueGrey.shade600))])),
          const SizedBox(width: 8), Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? AppTheme.blue : const Color(0xFFB7C0CE), size: 22),
        ]),
      ),
    ));
  }
}
