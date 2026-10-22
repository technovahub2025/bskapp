import 'dart:convert';

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
          IconButton(tooltip: 'Refresh', onPressed: () => setState(() { _projects = _loadProjects(); }), icon: const Icon(Icons.refresh_rounded)),
        ])),
        if (_assignedOnly) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: TextField(decoration: const InputDecoration(hintText: 'Optional site engineer filter', prefixIcon: Icon(Icons.person_search), isDense: true), onSubmitted: (value) => setState(() { _engineer = value.trim(); _projects = _loadProjects(); }))),
        Expanded(child: FutureBuilder<List<Project>>(future: _projects, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message('Could not load projects.\n${snapshot.error}', onRetry: () => setState(() { _projects = _loadProjects(); }));
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) return _message('No projects found.');
          return RefreshIndicator(onRefresh: () async { setState(() { _projects = _loadProjects(); }); }, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            ...projects.map((project) => Card(
              color: Colors.white,
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EstimatorProjectScreen(project: project, repository: _repository))),
                child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .34), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.apartment_rounded, color: AppTheme.orange)),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(project.title.isEmpty ? project.projectName : project.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.navy))), const SizedBox(width: 7), const Icon(Icons.chevron_right_rounded, color: AppTheme.orange, size: 21)]),
                    if (project.projectName.isNotEmpty && project.projectName != project.title) ...[const SizedBox(height: 3), Text(project.projectName, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500))],
                    const SizedBox(height: 8),
                    Text(project.description.isEmpty ? 'No description provided.' : project.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.35, color: Colors.blueGrey.shade700)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 7, runSpacing: 6, children: [
                      _projectMeta(Icons.engineering_rounded, project.siteEngineer?.isNotEmpty == true ? project.siteEngineer! : 'Unassigned'),
                      if (project.workflowStatus?.isNotEmpty == true) _projectMeta(Icons.fact_check_outlined, project.workflowStatus!),
                      _projectMeta(Icons.visibility_outlined, 'Read only'),
                    ]),
                  ])),
                ])),
              ),
            )),
          ]));
        })),
      ]));
}

Widget _projectMeta(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: AppTheme.orange), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.navy))]),
    );

class EstimatorProjectScreen extends StatelessWidget {
  const EstimatorProjectScreen({super.key, required this.project, required this.repository});
  final Project project;
  final EstimatorRepository repository;

  @override
  Widget build(BuildContext context) => DefaultTabController(length: 4, child: Scaffold(
        appBar: AppBar(title: Text(project.title.isEmpty ? project.projectName : project.title), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Measurements'), Tab(text: 'Labour'), Tab(text: 'Materials'), Tab(text: 'Issues')])),
        body: TabBarView(children: [
          _EstimatorReportList(type: 'measurement', projectId: project.id, repository: repository),
          _EstimatorReportList(type: 'labour', projectId: project.id, repository: repository),
          _EstimatorReportList(type: 'material', projectId: project.id, repository: repository),
          _EstimatorIssueList(projectId: project.id, repository: repository),
        ]),
      ));
}

class _EstimatorIssueList extends StatefulWidget {
  const _EstimatorIssueList({required this.projectId, required this.repository});
  final String projectId;
  final EstimatorRepository repository;

  @override
  State<_EstimatorIssueList> createState() => _EstimatorIssueListState();
}

class _EstimatorIssueListState extends State<_EstimatorIssueList> {
  late Future<List<Map<String, dynamic>>> _future = widget.repository.issues(widget.projectId);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() => _future = widget.repository.issues(widget.projectId)));
          final issues = snapshot.data ?? const <Map<String, dynamic>>[];
          if (issues.isEmpty) return _message('No issues reported for this project.');
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = widget.repository.issues(widget.projectId)),
            child: ListView(padding: const EdgeInsets.all(16), children: issues.map(_issueCard).toList()),
          );
        },
      );

  Widget _issueCard(Map<String, dynamic> issue) {
    final images = _imageValues(issue['images'] ?? issue['image']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .3), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.report_outlined, color: AppTheme.orange)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((issue['issueText'] ?? issue['description'] ?? 'Issue').toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy)),
              const SizedBox(height: 4),
              Text('Status: ${issue['status'] ?? 'submitted'}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
              if (issue['siteEngineer'] != null) Text('Reported by ${issue['siteEngineer']}', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
            ])),
          ]),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: images.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, index) => _issueImage(images[index]))),
          ],
        ]),
      ),
    );
  }

  Widget _issueImage(String source) {
    final value = source.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(value, width: 112, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()));
    }
    try {
      final bytes = value.startsWith('data:') ? UriData.fromUri(Uri.parse(value)).contentAsBytes() : base64Decode(value.replaceFirst(RegExp(r'^data:[^,]*,'), ''));
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: 112, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()));
    } catch (_) {
      return _imagePlaceholder();
    }
  }

  Widget _imagePlaceholder() => Container(width: 112, height: 92, decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.broken_image_outlined, color: AppTheme.orange));

  List<String> _imageValues(dynamic value) {
    if (value is String) return value.trim().isEmpty ? const [] : [value];
    if (value is List) return value.map((item) => item is String ? item : item is Map ? (item['url'] ?? item['data'] ?? item['image'] ?? '').toString() : '').where((item) => item.trim().isNotEmpty).toList();
    return const [];
  }
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
    if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() { _future = widget.repository.reports(widget.type, widget.projectId); }));
    final records = snapshot.data ?? const [];
    if (records.isEmpty) return _message('No ${widget.type} reports for this project.');
    return RefreshIndicator(
      onRefresh: () async { setState(() { _future = widget.repository.reports(widget.type, widget.projectId); }); },
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: records.map((record) {
        final status = (record['status'] ?? 'unknown').toString();
        final details = _detailEntries(record, widget.type);
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .28), borderRadius: BorderRadius.circular(14)), child: Icon(_reportIcon(widget.type), color: AppTheme.orange)),
                const SizedBox(width: 12),
                Expanded(child: Text(_title(record, widget.type), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navy))),
                _statusBadge(status),
              ]),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 15),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final entry in details)
                    Container(
                      constraints: const BoxConstraints(minWidth: 90, maxWidth: 165),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE3A3))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fieldLabel(entry.key), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade500)),
                        const SizedBox(height: 3),
                        Text(_displayValue(entry.value), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                      ]),
                    ),
                ]),
              ],
              if (record['createdAt'] != null) ...[
                const SizedBox(height: 14),
                Row(children: [Icon(Icons.schedule_rounded, size: 14, color: Colors.blueGrey.shade400), const SizedBox(width: 5), Text('Created ${record['createdAt']}', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500))]),
              ],
            ]),
          ),
        );
      }).toList()),
    );
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
          Card(color: Colors.white, elevation: 1.5, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
List<MapEntry<String, dynamic>> _detailEntries(Map<String, dynamic> report, String type) {
  final key = switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
  final value = report[key];
  final Map<String, dynamic>? fields = value is List && value.isNotEmpty && value.first is Map
      ? Map<String, dynamic>.from(value.first as Map)
      : value is Map ? Map<String, dynamic>.from(value) : null;
  final source = fields ?? report;
  return source.entries.where((entry) => !['_id', 'id', 'projectId', 'status', 'createdAt', 'updatedAt', '__v', 'siteEngineer', 'title'].contains(entry.key)).take(6).toList();
}
IconData _reportIcon(String type) => switch (type) {'measurement' => Icons.straighten_rounded, 'labour' => Icons.groups_rounded, _ => Icons.inventory_2_outlined};
String _fieldLabel(String field) => field.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match[1]}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match[0]!.toUpperCase());
String _displayValue(dynamic value) {
  final text = value is Map || value is List ? value.toString() : (value ?? '—').toString();
  return text.length > 46 ? '${text.substring(0, 43)}…' : text;
}
Widget _statusBadge(String status) {
  final approved = status.toLowerCase() == 'approved';
  final pending = ['pending', 'submitted', 'pending approval'].contains(status.toLowerCase());
  final color = approved ? const Color(0xFF21845C) : pending ? AppTheme.orange : Colors.blueGrey.shade600;
  final background = approved ? const Color(0xFFE7F5EC) : pending ? const Color(0xFFFFF1D2) : const Color(0xFFF3F0EB);
  return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)));
}
String _details(Map<String, dynamic> report, String type) {
  final key = switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
  final entries = report[key];
  if (entries is List && entries.isNotEmpty && entries.first is Map) return (entries.first as Map).entries.map((entry) => '${entry.key}: ${entry.value}').join(' · ');
  return report.entries.where((entry) => !['_id', 'status', 'createdAt', 'updatedAt', '__v'].contains(entry.key)).map((entry) => '${entry.key}: ${entry.value}').join(' · ');
}
