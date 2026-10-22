import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<List<Project>>? _assignedProjects;
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
          _assignedProjects ??= _loadAssignedProjects(name);
          return _projects(name, _assignedProjects!);
        },
      ));

  Future<List<Project>> _loadAssignedProjects(String name) async {
    final requestedName = name.trim();
    final projects = await widget.repository.assignedProjects(siteEngineer: requestedName);
    if (projects.isNotEmpty) return projects;

    // Some API implementations ignore the name filter or compare names with
    // different casing. Fetch the assigned list and match it consistently here.
    final allAssigned = await widget.repository.assignedProjects();
    final normalizedName = requestedName.toLowerCase();
    return allAssigned.where((project) => project.siteEngineer?.trim().toLowerCase() == normalizedName).toList();
  }

  Widget _projects(String name, Future<List<Project>> projectsFuture) => FutureBuilder<List<Project>>(
        future: projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message('Could not load assigned projects.\n${snapshot.error}', onRetry: () => setState(() { _assignedProjects = _loadAssignedProjects(name); }));
          final projects = snapshot.data ?? const <Project>[];
          return RefreshIndicator(onRefresh: () async => setState(() { _assignedProjects = _loadAssignedProjects(name); }), child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Hello, $name', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppTheme.navy)),
            const SizedBox(height: 5), Text('Your assigned projects', style: TextStyle(color: Colors.blueGrey.shade600)),
            const SizedBox(height: 20),
            if (projects.isEmpty) _message('No projects are assigned to you yet.')
            else ...projects.map((project) => Card(color: Colors.white, elevation: 1.5, margin: const EdgeInsets.only(bottom: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .34), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.apartment_rounded, color: AppTheme.orange)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project.title.isEmpty ? project.projectName : project.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                  if (project.projectName.isNotEmpty && project.projectName != project.title) Text(project.projectName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
                ])),
              ]),
              if (project.description.isNotEmpty) ...[const SizedBox(height: 12), Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.35, color: Colors.blueGrey.shade700))],
              const SizedBox(height: 13),
              Row(children: [
                Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.engineering_rounded, size: 15, color: AppTheme.orange), const SizedBox(width: 6), Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.navy)))]))),
                if (project.workflowStatus?.isNotEmpty == true) ...[const SizedBox(width: 7), _siteStatusBadge(project.workflowStatus!)],
              ]),
              const SizedBox(height: 13),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SiteProjectWorkflowScreen(project: project, siteEngineer: name, repository: _workflow))), icon: const Icon(Icons.assignment_outlined), label: const Text('Open reports'))),
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
      final preview = _previewPayload(data);
      final measurementCount = _count(_firstValue(preview, ['measurement', 'measurements', 'measurementReports', 'measurementReport', 'measurementCount']));
      final labourCount = _count(_firstValue(preview, ['labour', 'labours', 'labourReports', 'labourReport', 'labourCount']));
      final materialCount = _count(_firstValue(preview, ['material', 'materials', 'materialReports', 'materialReport', 'materialCount']));
      final readyValue = preview['readyToSubmit'] ?? preview['ready'] ?? preview['canSubmit'];
      final ready = readyValue == true || readyValue?.toString().toLowerCase() == 'true';
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Workflow preview'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Measurements: $measurementCount'),
          Text('Labour reports: $labourCount'),
          Text('Material reports: $materialCount'),
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
  void _load() {
    _future = widget.repository.reports(widget.type, projectId: widget.project.id, name: widget.name);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() { _load(); }));
          final reports = snapshot.data ?? const [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: Text('Add ${widget.type} report'))),
            const SizedBox(height: 10),
            if (reports.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No reports yet')))
            else ...reports.map((record) {
              final id = (record['_id'] ?? record['id'] ?? '').toString();
              return Card(color: Colors.white, elevation: 1.5, margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .3), borderRadius: BorderRadius.circular(12)), child: Icon(_siteReportIcon(widget.type), color: AppTheme.orange, size: 19)),
                title: Text(_recordTitle(record, widget.type), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy)),
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
    try { await widget.repository.createReport(widget.type, projectId: widget.project.id, name: widget.name, entry: entry); if (mounted) setState(() { _load(); }); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<void> _edit(Map<String, dynamic> report, String id) async {
    final field = _reportField(widget.type);
    final raw = report[field];
    final entry = raw is List && raw.isNotEmpty && raw.first is Map ? Map<String, dynamic>.from(raw.first as Map) : Map<String, dynamic>.from(report);
    final updated = await _entryDialog(widget.type, initial: entry);
    if (updated == null) return;
    try { await widget.repository.updateReport(widget.type, id, {field: [updated]}); if (mounted) setState(() { _load(); }); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<Map<String, dynamic>?> _entryDialog(String type, {Map<String, dynamic> initial = const {}}) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ReportEntryDialog(type: type, initial: initial),
    );
  }
}

class _ReportEntryDialog extends StatefulWidget {
  const _ReportEntryDialog({required this.type, required this.initial});
  final String type;
  final Map<String, dynamic> initial;

  @override
  State<_ReportEntryDialog> createState() => _ReportEntryDialogState();
}

class _ReportEntryDialogState extends State<_ReportEntryDialog> {
  late final List<String> _fields = switch (widget.type) {
    'measurement' => ['descriptionOfWork', 'nos', 'length', 'breadth', 'height', 'unit', 'qty'],
    'labour' => ['labour', 'nos', 'wages', 'total'],
    _ => ['item', 'qty', 'rate', 'total'],
  };
  late final Map<String, TextEditingController> _controllers = {
    for (final field in _fields) field: TextEditingController(text: widget.initial[field]?.toString() ?? ''),
  };
  final _formKey = GlobalKey<FormState>();

  void _recalculate() {
    final inputs = switch (widget.type) {
      'measurement' => const ['nos', 'length', 'breadth', 'height'],
      'labour' => const ['nos', 'wages'],
      _ => const <String>[],
    };
    if (inputs.isEmpty) return;
    final values = inputs.map((field) => num.tryParse(_controllers[field]!.text.trim())).toList();
    final outputField = widget.type == 'measurement' ? 'qty' : 'total';
    if (values.any((value) => value == null)) {
      _controllers[outputField]!.text = '';
      return;
    }
    num result = 1;
    for (final value in values) {
      result *= value!;
    }
    _controllers[outputField]!.text = _formatCalculatedValue(result);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('${widget.initial.isEmpty ? 'Add' : 'Edit'} ${widget.type} report'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final field in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controllers[field],
                    readOnly: (widget.type == 'measurement' && field == 'qty') || (widget.type == 'labour' && field == 'total'),
                    onChanged: (_) => _recalculate(),
                    keyboardType: _numericField(field) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: '${_label(field)}${(widget.type == 'measurement' && field == 'qty') || (widget.type == 'labour' && field == 'total') ? ' (calculated)' : ''}',
                      suffixIcon: ((widget.type == 'measurement' && field == 'qty') || (widget.type == 'labour' && field == 'total')) ? const Icon(Icons.auto_awesome_rounded, size: 18) : null,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final value = <String, dynamic>{};
              for (final field in _fields) {
                final text = _controllers[field]!.text.trim();
                value[field] = _numericField(field) ? (num.tryParse(text) ?? text) : text;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class _IssueEntryDialog extends StatefulWidget {
  const _IssueEntryDialog();

  @override
  State<_IssueEntryDialog> createState() => _IssueEntryDialogState();
}

class _IssueEntryDialogState extends State<_IssueEntryDialog> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _picking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_picking || _images.length >= 5) return;
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 75, maxWidth: 1600, maxHeight: 1600);
      if (!mounted || picked.isEmpty) return;
      setState(() => _images.addAll(picked.take(5 - _images.length)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not select images: $error')));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report an issue'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _controller, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Describe the issue')),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _picking || _images.length >= 5 ? null : _pickImages, icon: _picking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image_outlined), label: Text(_images.isEmpty ? 'Add images (up to 5)' : 'Add more images (${_images.length}/5)'))),
          if (_images.isNotEmpty) Wrap(spacing: 6, runSpacing: 4, children: [for (var index = 0; index < _images.length; index++) InputChip(label: Text(_images[index].name, overflow: TextOverflow.ellipsis), onDeleted: () => setState(() => _images.removeAt(index)))]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _IssueDraft(text: _controller.text.trim(), images: List.unmodifiable(_images))), child: const Text('Submit')),
        ],
      );
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
    if (snapshot.hasError) return _message(snapshot.error.toString(), onRetry: () => setState(() { _future = widget.repository.issues(); }));
    final issues = snapshot.data ?? const [];
    return ListView(padding: const EdgeInsets.all(16), children: [SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addIssue, icon: const Icon(Icons.report_gmailerrorred_rounded), label: const Text('Report an issue'))), const SizedBox(height: 10), if (issues.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No issues reported'))) else ...issues.map((issue) => Card(color: Colors.white, elevation: 1.5, child: ListTile(leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.yellow.withValues(alpha: .3), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.report_outlined, color: AppTheme.orange, size: 19)), title: Text((issue['issueText'] ?? issue['description'] ?? 'Issue').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)), subtitle: Text('Status: ${issue['status'] ?? 'submitted'}'))))]);
  });

  Future<void> _addIssue() async {
    final issue = await showDialog<_IssueDraft>(context: context, builder: (_) => const _IssueEntryDialog());
    if (issue == null) return;
    try {
      final images = await Future.wait(issue.images.map((image) async {
        final bytes = await image.readAsBytes();
        return 'data:${image.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
      }));
      await widget.repository.submitIssue(issue.text, images: images);
      if (mounted) setState(() { _future = widget.repository.issues(); });
    }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
}

class _IssueDraft {
  const _IssueDraft({required this.text, required this.images});
  final String text;
  final List<XFile> images;
}

Widget _message(String text, {VoidCallback? onRetry}) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again'))])));
Widget _siteStatusBadge(String status) {
  final color = switch (status.toLowerCase()) {
    'approved' => const Color(0xFF15956B),
    'rejected' => Colors.red.shade700,
    'submitted' || 'pending' || 'pending approval' => Colors.orange.shade800,
    _ => Colors.blueGrey.shade600,
  };
  return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(20)), child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}
String _reportField(String type) => switch (type) {'measurement' => 'measurementReport', 'labour' => 'labourReport', _ => 'materialReport'};
String _label(String field) => field.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match[0]!.toLowerCase()}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match[0]!.toUpperCase());
String _formatCalculatedValue(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}
bool _numericField(String field) => !['descriptionOfWork', 'unit', 'labour', 'item'].contains(field);
String _recordTitle(Map<String, dynamic> record, String type) => (record['title'] ?? record['projectname'] ?? record['siteEngineer'] ?? '${type[0].toUpperCase()}${type.substring(1)} report').toString();
IconData _siteReportIcon(String type) => switch (type) {'measurement' => Icons.straighten_rounded, 'labour' => Icons.groups_rounded, _ => Icons.inventory_2_outlined};
String _recordSummary(Map<String, dynamic> record, String type) {
  final data = record[_reportField(type)];
  if (data is List && data.isNotEmpty && data.first is Map) return (data.first as Map).entries.take(3).map((entry) => '${entry.key}: ${entry.value}').join(' · ');
  return record['createdAt']?.toString() ?? 'Tap edit to view details';
}
int _count(dynamic value) => value is List ? value.length : value == null ? 0 : 1;
Map<String, dynamic> _previewPayload(Map<String, dynamic> response) {
  var payload = response;
  for (var depth = 0; depth < 3; depth++) {
    final nested = payload['data'] ?? payload['preview'] ?? payload['result'] ?? payload['workflow'];
    if (nested is! Map) break;
    payload = {...payload, ...Map<String, dynamic>.from(nested)};
  }
  return payload;
}

dynamic _firstValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key)) return data[key];
  }
  return null;
}
