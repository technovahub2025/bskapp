import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/domain/auth_repository.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_repository.dart';
import '../data/site_engineer_repository.dart';

class SiteEngineerHome extends StatefulWidget {
  const SiteEngineerHome({super.key, required this.repository, required this.authRepository, required this.onSignOut});
  final ProjectRepository repository;
  final AuthRepository authRepository;
  final VoidCallback onSignOut;

  @override
  State<SiteEngineerHome> createState() => _SiteEngineerHomeState();
}

class _SiteEngineerHomeState extends State<SiteEngineerHome> {
  late final Future<String?> _name = widget.authRepository.readEngineerName();
  final _api = ProjectEngineerApi();
  final _storage = TokenStorage();
  late final SiteEngineerRepository _workflow = SiteEngineerRepository(api: _api, tokenStorage: _storage, projects: widget.repository);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Site Engineer workspace'), actions: [IconButton(tooltip: 'Sign out', onPressed: widget.onSignOut, icon: const Icon(Icons.logout_rounded))]),
        body: FutureBuilder<String?>(
        future: _name,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final name = snapshot.data;
          if (name == null || name.isEmpty) return const Center(child: Text('Engineer name not found. Please sign in again.'));
          return _projects(name);
        },
      ));

  Widget _projects(String name) => FutureBuilder<List<Project>>(
        future: widget.repository.assignedProjects(siteEngineer: name),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message('Could not load assigned projects.\n${snapshot.error}', onRetry: () => setState(() {}));
          final projects = snapshot.data ?? const <Project>[];
          return RefreshIndicator(onRefresh: () async => setState(() {}), child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Hello, $name', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppTheme.navy)),
            const SizedBox(height: 5), Text('Your assigned projects', style: TextStyle(color: Colors.blueGrey.shade600)),
            const SizedBox(height: 20),
            if (projects.isEmpty) _message('No projects are assigned to you yet.')
            else ...projects.map((project) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE8ECF2))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(project.title.isEmpty ? project.projectName : project.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navy)),
              const SizedBox(height: 6), Text(project.description, style: TextStyle(color: Colors.blueGrey.shade600)),
              const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SiteProjectWorkflowScreen(project: project, siteEngineer: name, repository: _workflow))), icon: const Icon(Icons.assignment_outlined), label: const Text('Open reports'))),
            ])))),
          ]));
        },
      );
}

class SiteProjectWorkflowScreen extends StatelessWidget {
  const SiteProjectWorkflowScreen({super.key, required this.project, required this.siteEngineer, required this.repository});
  final Project project;
  final String siteEngineer;
  final SiteEngineerRepository repository;

  @override
  Widget build(BuildContext context) => DefaultTabController(length: 4, child: Scaffold(
        appBar: AppBar(title: Text(project.title.isEmpty ? project.projectName : project.title), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Measurement'), Tab(text: 'Labour'), Tab(text: 'Material'), Tab(text: 'Issues')])),
        body: TabBarView(children: [
          _ReportList(type: 'measurement', project: project, name: siteEngineer, repository: repository),
          _ReportList(type: 'labour', project: project, name: siteEngineer, repository: repository),
          _ReportList(type: 'material', project: project, name: siteEngineer, repository: repository),
          _IssueList(repository: repository),
        ]),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: FilledButton.icon(onPressed: () => _preview(context), icon: const Icon(Icons.fact_check_outlined), label: const Text('Preview & submit workflow')))),
      ));

  Future<void> _preview(BuildContext context) async {
    try {
      final data = await repository.preview(projectId: project.id, name: siteEngineer);
      if (!context.mounted) return;
      final ready = data['readyToSubmit'] == true;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Workflow preview'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Measurements: ${_count(data['measurement'] ?? data['measurements'])}'),
          Text('Labour reports: ${_count(data['labour'] ?? data['labours'])}'),
          Text('Material reports: ${_count(data['material'] ?? data['materials'])}'),
          const SizedBox(height: 10), Text(ready ? 'All report types are ready to submit.' : 'Add at least one measurement, labour, and material report before submitting.', style: TextStyle(color: ready ? Colors.green.shade700 : Colors.orange.shade800)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')), if (ready) FilledButton(onPressed: () async { Navigator.pop(dialogContext); try { await repository.submit(projectId: project.id, name: siteEngineer); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow submitted'))); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); } }, child: const Text('Submit'))],
      ));
    } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
}

class _ReportList extends StatefulWidget {
  const _ReportList({required this.type, required this.project, required this.name, required this.repository});
  final String type;
  final Project project;
  final String name;
  final SiteEngineerRepository repository;
  @override
  State<_ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<_ReportList> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = widget.repository.reports(widget.type, projectId: widget.project.id, name: widget.name);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(_load));
          final reports = snapshot.data ?? const [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: Text('Add ${widget.type} report'))),
            const SizedBox(height: 10),
            if (reports.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No reports yet')))
            else ...reports.map((record) {
              final id = (record['_id'] ?? record['id'] ?? '').toString();
              return Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: ListTile(
                title: Text(_recordTitle(record, widget.type), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Status: ${record['status'] ?? 'draft'}  •  ${_recordSummary(record, widget.type)}'),
                trailing: IconButton(tooltip: 'Edit report', onPressed: id.isEmpty ? null : () => _edit(record, id), icon: const Icon(Icons.edit_outlined)),
              ));
            }),
          ]);
        },
      );

  Future<void> _add() async {
    final entry = await _entryDialog(widget.type);
    if (entry == null) return;
    try { await widget.repository.createReport(widget.type, projectId: widget.project.id, name: widget.name, entry: entry); if (mounted) setState(_load); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<void> _edit(Map<String, dynamic> report, String id) async {
    final field = _reportField(widget.type);
    final raw = report[field];
    final entry = raw is List && raw.isNotEmpty && raw.first is Map ? Map<String, dynamic>.from(raw.first as Map) : Map<String, dynamic>.from(report);
    final updated = await _entryDialog(widget.type, initial: entry);
    if (updated == null) return;
    try { await widget.repository.updateReport(widget.type, id, {field: [updated]}); if (mounted) setState(_load); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<Map<String, dynamic>?> _entryDialog(String type, {Map<String, dynamic> initial = const {}}) async {
    final fields = switch (type) {
      'measurement' => ['descriptionOfWork', 'nos', 'length', 'breadth', 'height', 'unit', 'qty'],
      'labour' => ['labour', 'nos', 'wages', 'total'],
      _ => ['item', 'qty', 'rate', 'total'],
    };
    final controllers = {for (final field in fields) field: TextEditingController(text: initial[field]?.toString() ?? '')};
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (context) => AlertDialog(
      title: Text('${initial.isEmpty ? 'Add' : 'Edit'} $type report'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final field in fields) Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: controllers[field], keyboardType: _numericField(field) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: _label(field)), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null))]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (!formKey.currentState!.validate()) return; final value = <String, dynamic>{}; for (final field in fields) { final text = controllers[field]!.text.trim(); value[field] = _numericField(field) ? (num.tryParse(text) ?? text) : text; } Navigator.pop(context, value); }, child: const Text('Save'))],
    ));
    for (final controller in controllers.values) { controller.dispose(); }
    return result;
  }
}

class _IssueList extends StatefulWidget {
  const _IssueList({required this.repository});
  final SiteEngineerRepository repository;
  @override
  State<_IssueList> createState() => _IssueListState();
}

class _IssueListState extends State<_IssueList> {
  late Future<List<Map<String, dynamic>>> _future = widget.repository.issues();
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() => _future = widget.repository.issues()));
    final issues = snapshot.data ?? const [];
    return ListView(padding: const EdgeInsets.all(16), children: [SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addIssue, icon: const Icon(Icons.report_gmailerrorred_rounded), label: const Text('Report an issue'))), const SizedBox(height: 10), if (issues.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No issues reported'))) else ...issues.map((issue) => Card(color: Colors.white, elevation: 0, child: ListTile(title: Text((issue['issueText'] ?? issue['description'] ?? 'Issue').toString()), subtitle: Text('Status: ${issue['status'] ?? 'submitted'}'))))]);
  });

  Future<void> _addIssue() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Report an issue'), content: TextField(controller: controller, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Describe the issue')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Submit'))]));
    controller.dispose();
    if (text == null) return;
    try { await widget.repository.submitIssue(text); if (mounted) setState(() => _future = widget.repository.issues()); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
}

Widget _message(String text, {VoidCallback? onRetry}) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again'))])));
String _reportField(String type) => switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
String _label(String field) => field.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match[0]!.toLowerCase()}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match[0]!.toUpperCase());
bool _numericField(String field) => !['descriptionOfWork', 'unit', 'labour', 'item'].contains(field);
String _recordTitle(Map<String, dynamic> record, String type) => (record['title'] ?? record['projectname'] ?? record['siteEngineer'] ?? '${type[0].toUpperCase()}${type.substring(1)} report').toString();
String _recordSummary(Map<String, dynamic> record, String type) {
  final data = record[_reportField(type)];
  if (data is List && data.isNotEmpty && data.first is Map) return (data.first as Map).entries.take(3).map((entry) => '${entry.key}: ${entry.value}').join(' · ');
  return record['createdAt']?.toString() ?? 'Tap edit to view details';
}
int _count(dynamic value) => value is List ? value.length : value == null ? 0 : 1;
