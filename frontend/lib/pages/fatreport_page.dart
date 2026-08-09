import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../services/api.dart';
import 'report_values_page.dart';
import 'report_templates_page.dart';

class FATReportItem {
  int id;
  String text;

  FATReportItem({required this.id, required this.text});

  factory FATReportItem.fromJson(Map<String, dynamic> j) => FATReportItem(
        id: j['id'] as int,
        text: j['text'] as String,
      );
}

class ReportTemplateItem {
  int id;
  String text;
  int order;

  ReportTemplateItem({required this.id, required this.text, required this.order});

  factory ReportTemplateItem.fromJson(Map<String, dynamic> j) => ReportTemplateItem(
        id: j['id'] as int,
        text: j['text'] as String,
        order: j['order'] as int,
      );
}

class FATReportPage extends StatefulWidget {
  const FATReportPage({super.key});

  @override
  State<FATReportPage> createState() => _FATReportPageState();
}

class _FATReportPageState extends State<FATReportPage> {
  List<FATReportItem> _items = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Api.fetchFATReports();
      _items = list.map<FATReportItem>((e) => FATReportItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida kraunant ataskaitas: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<FATReportItem> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) => e.text.toLowerCase().contains(q)).toList();
  }

  Future<void> _createOrEdit({FATReportItem? existing}) async {
    final ctrl = TextEditingController(text: existing?.text ?? '');
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas FAT ataskaita' : 'Redaguoti ataskaitą'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Tekstas')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );
    if (ok != true) return;

    final text = ctrl.text.trim();
    if (text.isEmpty) return;

    try {
      if (existing == null) {
        final created = await Api.createFATReport({'text': text});
        setState(() => _items.add(FATReportItem.fromJson(created)));
      } else {
        final payload = {'id': existing.id, 'text': text};
        await Api.updateFATReport(existing.id, payload);
        setState(() => existing.text = text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(FATReportItem it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti ataskaitą?'),
        content: Text('Ar tikrai ištrinti "${it.text}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteFATReport(it.id);
      setState(() => _items.removeWhere((e) => e.id == it.id));
      web.window.location.reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  Future<void> _manageTemplates(FATReportItem report) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportTemplatesPage(fatReportId: report.id, fatReportText: report.text)));
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filtered();
    return Scaffold(
      appBar: AppBar(title: const Text('FAT Ataskaitos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Nauja ataskaita'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Paieška pagal tekstą'),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: shown.isEmpty
                              ? Center(
                                  child: Text('Nėra ataskaitų', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                )
                              : ListView.separated(
                                  itemCount: shown.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, index) {
                                    final it = shown[index];
                                    return Card(
                                      margin: EdgeInsets.zero,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(it.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              alignment: WrapAlignment.end,
                                              children: [
                                                IconButton(onPressed: () => _manageTemplates(it), icon: const Icon(Icons.view_list), tooltip: 'Valdyti šablonus'),
                                                IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportValuesPage(fatReportId: it.id, fatReportText: it.text))), icon: const Icon(Icons.description), tooltip: 'Valdyti reikšmes'),
                                                IconButton(onPressed: () => _createOrEdit(existing: it), icon: const Icon(Icons.edit), tooltip: 'Redaguoti'),
                                                IconButton(onPressed: () => _delete(it), icon: const Icon(Icons.delete), tooltip: 'Ištrinti'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


