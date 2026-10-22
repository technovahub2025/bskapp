import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../data/project_engineer_api.dart';
import '../domain/app_role.dart';
import '../domain/auth_repository.dart';
import '../../projects/domain/project_repository.dart';
import 'role_home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.role, required this.repository, required this.projectRepository});
  final AppRole role;
  final AuthRepository repository;
  final ProjectRepository projectRepository;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameOrPhone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() { _nameOrPhone.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.repository.login(role: widget.role, name: _nameOrPhone.text.trim(), password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => RoleHomeScreen(role: widget.role, authRepository: widget.repository, projectRepository: widget.projectRepository)), (route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect. Check your server URL and try again.'), behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.role != AppRole.contractor;
    final isSiteEngineer = widget.role == AppRole.siteEngineer;
    return Scaffold(appBar: AppBar(backgroundColor: AppTheme.canvas, title: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy))), body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 32), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 58, height: 58, decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: .1), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.lock_person_rounded, color: AppTheme.blue, size: 29)),
      const SizedBox(height: 22), Text('${widget.role.label}\nsign in', style: const TextStyle(fontSize: 29, height: 1.15, fontWeight: FontWeight.w800, color: AppTheme.navy)),
      const SizedBox(height: 10), Text(enabled ? (isSiteEngineer ? 'Sign in with the name used for your project assignment.' : 'Use your registered phone number and password.') : 'This role’s sign-in endpoint has not been provided yet.', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14)),
      if (!enabled) ...[
        const SizedBox(height: 20), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF5DF), borderRadius: BorderRadius.circular(13)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: Color(0xFF9B6900)), SizedBox(width: 10), Expanded(child: Text('You can choose this role now. Connect its login API to enable account access.', style: TextStyle(color: Color(0xFF75520A), height: 1.4)))])),
      ],
      const SizedBox(height: 28), Text(isSiteEngineer ? 'ENGINEER NAME' : 'PHONE NUMBER', style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppTheme.navy)), const SizedBox(height: 9),
      TextFormField(controller: _nameOrPhone, enabled: enabled, keyboardType: isSiteEngineer ? TextInputType.name : TextInputType.phone, textInputAction: TextInputAction.next, decoration: InputDecoration(hintText: isSiteEngineer ? 'Enter your assigned name' : 'Enter your phone number', prefixIcon: Icon(isSiteEngineer ? Icons.person_outline_rounded : Icons.phone_iphone_rounded)), validator: (v) => v == null || v.trim().length < (isSiteEngineer ? 2 : 7) ? (isSiteEngineer ? 'Enter your name' : 'Enter a valid phone number') : null),
      const SizedBox(height: 19), const Text('PASSWORD', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppTheme.navy)), const SizedBox(height: 9),
      TextFormField(controller: _password, enabled: enabled, obscureText: _obscure, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => enabled ? _submit() : null, decoration: InputDecoration(hintText: 'Enter your password', prefixIcon: const Icon(Icons.key_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined))), validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null),
      const SizedBox(height: 26), SizedBox(width: double.infinity, height: 55, child: FilledButton(onPressed: enabled && !_loading ? _submit : null, style: FilledButton.styleFrom(backgroundColor: AppTheme.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _loading ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
    ])))));
  }
}
