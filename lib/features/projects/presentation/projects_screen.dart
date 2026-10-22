import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../../estimator/data/estimator_repository.dart';
import '../../estimator/presentation/estimator_home.dart';
import '../domain/project.dart';
import '../domain/project_repository.dart';

Color _workflowColor(String status) => switch (status.toLowerCase()) {
      'approved' => const Color(0xFF15956B),
      'rejected' => Colors.red.shade700,
      'submitted' || 'pending' || 'pending approval' => Colors.orange.shade800,
      _ => Colors.blueGrey.shade600,
    };

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.repository});
  final ProjectRepository repository;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectFormDialog extends StatefulWidget {
  const _ProjectFormDialog({required this.title, required this.projectName, required this.projectTitle, required this.description, required this.edit});
  final String title;
  final String projectName;
  final String projectTitle;
  final String description;
  final bool edit;

  @override
  State<_ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<_ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.projectName);
  late final _projectTitle = TextEditingController(text: widget.projectTitle);
  late final _description = TextEditingController(text: widget.description);

  @override
  void dispose() {
    _name.dispose();
    _projectTitle.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (!widget.edit) ...[
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Project name'), validator: _required),
                const SizedBox(height: 12),
              ],
              TextFormField(controller: _projectTitle, decoration: const InputDecoration(labelText: 'Title'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), minLines: 2, maxLines: 4, validator: _required),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, [_name.text.trim(), _projectTitle.text.trim(), _description.text.trim()]);
              }
            },
            child: Text(widget.edit ? 'Save' : 'Create'),
          ),
        ],
      );
}

class _AssignEngineerDialog extends StatefulWidget {
  const _AssignEngineerDialog({required this.initialValue});
  final String initialValue;

  @override
  State<_AssignEngineerDialog> createState() => _AssignEngineerDialogState();
}

class _AssignEngineerDialogState extends State<_AssignEngineerDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Assign site engineer'),
        content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(labelText: 'Engineer name', hintText: 'e.g. Alex')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (_controller.text.trim().isNotEmpty) Navigator.pop(context, _controller.text.trim()); }, child: const Text('Assign')),
        ],
      );
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  ProjectCounts _counts = const ProjectCounts();
  List<Project> _projects = const [];
  bool _loading = true;
  bool _assignedOnly = false;
  String _engineerFilter = '';
  String? _error;
  String? _reviewingProjectId;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait([widget.repository.counts(), widget.repository.projects()]);
      if (!mounted) return;
      final allProjects = values[1] as List<Project>;
      final apiCounts = values[0] as ProjectCounts;
      final visibleProjects = _assignedOnly
          ? await widget.repository.assignedProjects(siteEngineer: _engineerFilter.isEmpty ? null : _engineerFilter)
          : allProjects;
      if (!mounted) return;
      final assigned = allProjects.where((project) => project.siteEngineer?.trim().isNotEmpty == true).length;
      setState(() {
        _counts = ProjectCounts(
          total: apiCounts.total == 0 && allProjects.isNotEmpty ? allProjects.length : apiCounts.total,
          assigned: apiCounts.assigned == 0 && assigned > 0 ? assigned : apiCounts.assigned,
          unassigned: apiCounts.total == 0 && allProjects.isNotEmpty ? allProjects.length - assigned : apiCounts.unassigned,
        );
        _projects = visibleProjects;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Projects', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(tooltip: 'Refresh', onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
        floatingActionButton: FloatingActionButton.extended(onPressed: _createProject, icon: const Icon(Icons.add_rounded), label: const Text('New project')),
        body: RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
          Text('PROJECT OVERVIEW', style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _stat('Total', _counts.total, Icons.apartment_rounded, AppTheme.orange)), const SizedBox(width: 10), Expanded(child: _stat('Assigned', _counts.assigned, Icons.assignment_turned_in_rounded, const Color(0xFF15956B))), const SizedBox(width: 10), Expanded(child: _stat('Open', _counts.unassigned, Icons.pending_actions_rounded, const Color(0xFFE09A27)))]),
          const SizedBox(height: 27),
          Row(children: [const Expanded(child: Text('Project list', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.navy))), FilterChip(label: Text(_assignedOnly ? 'Assigned' : 'All projects'), selected: _assignedOnly, onSelected: (value) { setState(() => _assignedOnly = value); _refresh(); })]),
          if (_assignedOnly) ...[
            const SizedBox(height: 8), TextField(decoration: const InputDecoration(hintText: 'Filter by site engineer', prefixIcon: Icon(Icons.person_search_rounded), isDense: true), onSubmitted: (value) { _engineerFilter = value; _refresh(); }),
          ],
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) _errorCard()
          else if (_projects.isEmpty) _emptyState()
          else ..._projects.map(_projectCard),
        ])),
      );

  Widget _stat(String label, int value, IconData icon, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 12), Text('$value', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppTheme.navy)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600))]));

  Widget _projectCard(Project project) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(project.title.isEmpty ? project.projectName : project.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.navy))), PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') { _editProject(project); } else if (value == 'assign') { _assignProject(project); } else { _viewProject(project); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'view', child: Text('View project')), PopupMenuItem(value: 'edit', child: Text('Edit details')), PopupMenuItem(value: 'assign', child: Text('Assign engineer'))])]),
    if (project.projectName.isNotEmpty && project.projectName != project.title) Text(project.projectName, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12)),
    if (project.workflowStatus?.isNotEmpty == true) ...[
      const SizedBox(height: 5),
      Text('Workflow: ${project.workflowStatus}', style: TextStyle(color: _workflowColor(project.workflowStatus!), fontSize: 12, fontWeight: FontWeight.w700)),
    ],
    const SizedBox(height: 5), Text(project.description.isEmpty ? 'No description provided.' : project.description, style: TextStyle(color: Colors.blueGrey.shade700, height: 1.35)),
    const SizedBox(height: 12), Row(children: [Icon(Icons.engineering_rounded, size: 16, color: Colors.blueGrey.shade400), const SizedBox(width: 6), Text(project.siteEngineer?.isNotEmpty == true ? project.siteEngineer! : 'Unassigned', style: TextStyle(fontSize: 12, color: project.siteEngineer?.isNotEmpty == true ? const Color(0xFF15956B) : Colors.blueGrey.shade500, fontWeight: FontWeight.w600))]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => _viewProject(project), icon: const Icon(Icons.visibility_outlined), label: const Text('View project'))),
      if (project.siteEngineer?.trim().isNotEmpty == true && !['approved', 'rejected'].contains(project.workflowStatus?.trim().toLowerCase())) ...[
        const SizedBox(width: 8),
        IconButton(tooltip: 'Reject workflow', onPressed: _reviewingProjectId == project.id ? null : () => _reviewWorkflow(project, approve: false), color: Colors.red.shade700, icon: const Icon(Icons.close_rounded)),
        IconButton(tooltip: 'Approve workflow', onPressed: _reviewingProjectId == project.id ? null : () => _reviewWorkflow(project, approve: true), color: const Color(0xFF15956B), icon: const Icon(Icons.check_rounded)),
      ],
    ]),
  ])));

  void _viewProject(Project project) {
    final repository = EstimatorRepository(api: ProjectEngineerApi(), tokenStorage: TokenStorage());
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EstimatorProjectScreen(project: project, repository: repository)));
  }

  Future<void> _reviewWorkflow(Project project, {required bool approve}) async {
    final action = approve ? 'approve' : 'reject';
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('${approve ? 'Approve' : 'Reject'} workflow?'),
      content: Text('This will $action the submitted reports for ${project.title.isEmpty ? project.projectName : project.title}.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(approve ? 'Approve' : 'Reject'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _reviewingProjectId = project.id);
    try {
      if (approve) {
        await widget.repository.approveWorkflow(project);
      } else {
        await widget.repository.rejectWorkflow(project);
      }
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Workflow ${approve ? 'approved' : 'rejected'}')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _reviewingProjectId = null);
    }
  }

  Widget _errorCard() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [const Icon(Icons.cloud_off_rounded, color: Colors.deepOrange), const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: _refresh, child: const Text('Try again'))]));
  Widget _emptyState() => Container(padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(Icons.folder_open_rounded, size: 36, color: Colors.blueGrey.shade300), const SizedBox(height: 10), const Text('No projects found', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('Create a project to see it here.', style: TextStyle(color: Colors.blueGrey.shade500))]));

  Future<void> _createProject() async {
    final values = await _projectDialog(title: 'Create project', projectName: '', projectTitle: '', description: '');
    if (values == null) return;
    await _action(() => widget.repository.create(projectName: values[0], title: values[1], description: values[2]));
  }

  Future<void> _editProject(Project project) async {
    final values = await _projectDialog(title: 'Update project', projectName: project.projectName, projectTitle: project.title, description: project.description, edit: true);
    if (values == null) return;
    await _action(() => widget.repository.update(project, title: values[1], description: values[2]));
  }

  Future<List<String>?> _projectDialog({required String title, required String projectName, required String projectTitle, required String description, bool edit = false}) async {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => _ProjectFormDialog(title: title, projectName: projectName, projectTitle: projectTitle, description: description, edit: edit),
    );
  }

  Future<void> _assignProject(Project project) async {
    final value = await showDialog<String>(context: context, builder: (_) => _AssignEngineerDialog(initialValue: project.siteEngineer ?? ''));
    if (value == null) return;
    await _action(() => widget.repository.assign(project, siteEngineer: value));
  }

  Future<void> _action(Future<void> Function() action) async {
    try { await action(); await _refresh(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project saved successfully'))); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), behavior: SnackBarBehavior.floating)); }
  }
}
