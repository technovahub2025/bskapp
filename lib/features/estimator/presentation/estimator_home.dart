import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../auth/data/project_engineer_api.dart';
import '../../auth/data/token_storage.dart';
import '../../projects/domain/project.dart';
import '../data/estimator_repository.dart';

class EstimatorHome extends StatefulWidget {
  const EstimatorHome({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  State<EstimatorHome> createState() => _EstimatorHomeState();
}

class _EstimatorHomeState extends State<EstimatorHome> {
  late final _repository = EstimatorRepository(api: ProjectEngineerApi(), tokenStorage: TokenStorage());
  bool _assignedOnly = false;
  String _engineer = '';
  late Future<List<Project>> _projects = _loadProjects();

  Future<List<Project>> _loadProjects() => _assignedOnly
      ? _repository.assignedProjects(siteEngineer: _engineer.isEmpty ? null : _engineer)
      : _repository.projects();

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Estimator workspace'), actions: [IconButton(tooltip: 'Sign out', onPressed: widget.onSignOut, icon: const Icon(Icons.logout_rounded))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 10, 12, 8), child: Row(children: [
          const Expanded(child: Text('Read-only project data', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w700))),
          DropdownButton<bool>(value: _assignedOnly, items: const [DropdownMenuItem(value: false, child: Text('All projects')), DropdownMenuItem(value: true, child: Text('Assigned'))], onChanged: (value) { if (value == null) return; setState(() { _assignedOnly = value; _projects = _loadProjects(); }); }),
          IconButton(tooltip: 'Refresh', onPressed: () => setState(() => _projects = _loadProjects()), icon: const Icon(Icons.refresh_rounded)),
        ])),
        if (_assignedOnly) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: TextField(decoration: const InputDecoration(hintText: 'Optional site engineer filter', prefixIcon: Icon(Icons.person_search), isDense: true), onSubmitted: (value) => setState(() { _engineer = value.trim(); _projects = _loadProjects(); }))),
        Expanded(child: FutureBuilder<List<Project>>(future: _projects, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message('Could not load projects.\n${snapshot.error}', onRetry: () => setState(() => _projects = _loadProjects()));
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) return _message('No projects found.');
          return RefreshIndicator(onRefresh: () async => setState(() => _projects = _loadProjects()), child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            ...projects.map((project) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE7EBF1))), child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              title: Text(project.title.isEmpty ? project.projectName : project.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text('${project.description}\n${project.siteEngineer == null ? 'No engineer assigned' : 'Site Engineer: ${project.siteEngineer}'}', maxLines: 3, overflow: TextOverflow.ellipsis)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EstimatorProjectScreen(project: project, repository: _repository))),
            ))),
          ]));
        })),
      ]));
}

class EstimatorProjectScreen extends StatelessWidget {
  const EstimatorProjectScreen({super.key, required this.project, required this.repository});
  final Project project;
  final EstimatorRepository repository;

  @override
  Widget build(BuildContext context) => DefaultTabController(length: 4, child: Scaffold(
        appBar: AppBar(title: Text(project.title.isEmpty ? project.projectName : project.title), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Measurements'), Tab(text: 'Labour'), Tab(text: 'Materials'), Tab(text: 'Workflow')])),
        body: TabBarView(children: [
          _EstimatorReportList(type: 'measurement', projectId: project.id, repository: repository),
          _EstimatorReportList(type: 'labour', projectId: project.id, repository: repository),
          _EstimatorReportList(type: 'material', projectId: project.id, repository: repository),
          _WorkflowPreview(project: project, repository: repository),
        ]),
      ));
}

class _EstimatorReportList extends StatefulWidget {
  const _EstimatorReportList({required this.type, required this.projectId, required this.repository});
  final String type;
  final String projectId;
  final EstimatorRepository repository;
  @override
  State<_EstimatorReportList> createState() => _EstimatorReportListState();
}

class _EstimatorReportListState extends State<_EstimatorReportList> {
  late Future<List<Map<String, dynamic>>> _future = widget.repository.reports(widget.type, widget.projectId);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() => _future = widget.repository.reports(widget.type, widget.projectId)));
    final records = snapshot.data ?? const [];
    if (records.isEmpty) return _message('No ${widget.type} reports for this project.');
    return RefreshIndicator(onRefresh: () async => setState(() => _future = widget.repository.reports(widget.type, widget.projectId)), child: ListView(padding: const EdgeInsets.all(16), children: records.map((record) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_title(record, widget.type), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy)),
      const SizedBox(height: 6), Text('Status: ${record['status'] ?? 'unknown'}', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
      const SizedBox(height: 8), Text(_details(record, widget.type), style: TextStyle(color: Colors.blueGrey.shade700, height: 1.45)),
      if (record['createdAt'] != null) ...[const SizedBox(height: 6), Text('Created: ${record['createdAt']}', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400))],
    ])))).toList()));
  });
}

class _WorkflowPreview extends StatefulWidget {
  const _WorkflowPreview({required this.project, required this.repository});
  final Project project;
  final EstimatorRepository repository;
  @override
  State<_WorkflowPreview> createState() => _WorkflowPreviewState();
}

class _WorkflowPreviewState extends State<_WorkflowPreview> {
  final _engineer = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  @override
  void initState() { super.initState(); _engineer.text = widget.project.siteEngineer ?? ''; }
  @override
  void dispose() { _engineer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('Preview combined report status for this project.', style: TextStyle(color: Colors.blueGrey.shade600)),
        const SizedBox(height: 16), TextField(controller: _engineer, decoration: const InputDecoration(labelText: 'Site engineer', hintText: 'Required by workflow preview')),
        const SizedBox(height: 12), FilledButton(onPressed: _loading ? null : _load, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Load preview')),
        if (_result != null) ...[
          const SizedBox(height: 18),
          Card(color: Colors.white, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_result!['readyToSubmit'] == true ? 'Ready to submit' : 'Not ready to submit', style: TextStyle(fontWeight: FontWeight.w800, color: _result!['readyToSubmit'] == true ? Colors.green.shade700 : Colors.orange.shade800)),
            const SizedBox(height: 10), Text(_result!.entries.where((entry) => entry.key != 'readyToSubmit' && entry.key != 'success' && entry.key != 'message').map((entry) => '${entry.key}: ${entry.value is List ? (entry.value as List).length : entry.value}').join('\n')),
          ]))),
        ],
      ]);

  Future<void> _load() async {
    if (_engineer.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a site engineer name.'))); return; }
    setState(() => _loading = true);
    try { final result = await widget.repository.preview(widget.project.id, _engineer.text.trim()); if (mounted) setState(() => _result = result); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _loading = false); }
  }
}

Widget _message(String message, {VoidCallback? onRetry}) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center), if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again'))])));
String _title(Map<String, dynamic> report, String type) => (report['title'] ?? report['siteEngineer'] ?? '${type[0].toUpperCase()}${type.substring(1)} report').toString();
String _details(Map<String, dynamic> report, String type) {
  final key = switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
  final entries = report[key];
  if (entries is List && entries.isNotEmpty && entries.first is Map) return (entries.first as Map).entries.map((entry) => '${entry.key}: ${entry.value}').join(' · ');
  return report.entries.where((entry) => !['_id', 'status', 'createdAt', 'updatedAt', '__v'].contains(entry.key)).map((entry) => '${entry.key}: ${entry.value}').join(' · ');
}
