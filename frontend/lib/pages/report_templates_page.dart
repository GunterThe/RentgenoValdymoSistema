import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class ReportTemplate {
  int id;
  String text;
  int order;

  ReportTemplate({required this.id, required this.text, required this.order});

  factory ReportTemplate.fromJson(Map<String, dynamic> j) => ReportTemplate(
        id: j['id'] as int,
        text: j['text'] as String,
        order: j['order'] as int,
      );
}

class ReportTemplatesPage extends StatefulWidget {
  final int fatReportId;
  final String fatReportText;
  const ReportTemplatesPage({super.key, required this.fatReportId, required this.fatReportText});

  @override
  State<ReportTemplatesPage> createState() => _ReportTemplatesPageState();
}

class _ReportTemplatesPageState extends State<ReportTemplatesPage> {
  List<ReportTemplate> _items = [];
  bool _loading = true;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Api.fetchReportTemplates(widget.fatReportId);
      _items = (list).map((e) => ReportTemplate.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida kraunant šablonus: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({ReportTemplate? existing}) async {
    final ctrl = TextEditingController(text: existing?.text ?? '');
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas šablonas' : 'Redaguoti šabloną'),
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
        final created = await Api.createReportTemplate({'text': text, 'fatReportId': widget.fatReportId, 'order': (_items.length + 1)});
        setState(() => _items.add(ReportTemplate.fromJson(created)));
      } else {
        final payload = {'id': existing.id, 'text': text, 'fatReportId': widget.fatReportId, 'order': existing.order};
        await Api.updateReportTemplate(existing.id, payload);
        setState(() => existing.text = text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(ReportTemplate it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti šabloną?'),
        content: Text('Ar tikrai ištrinti "${it.text}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteReportTemplate(it.id);
      setState(() => _items.removeWhere((e) => e.id == it.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_reordering) return;
    if (oldIndex < 0 || oldIndex >= _items.length) return;

    setState(() => _reordering = true);
    try {
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = _items.removeAt(oldIndex);
      _items.insert(newIndex, moved);

      final newOrder = newIndex + 1;
      final payload = {
        'id': moved.id,
        'text': moved.text,
        'fatReportId': widget.fatReportId,
        'order': newOrder,
      };
      await Api.updateReportTemplate(moved.id, payload);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida rikiuojant: $e')));
      await _load();
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Šablonai: ${widget.fatReportText}',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _items.isEmpty
                              ? Center(child: Text('Nėra šablonų', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                              : ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  onReorder: _onReorder,
                                  itemCount: _items.length,
                                  itemBuilder: (ctx, i) {
                                    final it = _items[i];
                                    return Column(
                                      key: ValueKey(it.id),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text('${it.order}. ${it.text}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(onPressed: _reordering ? null : () => _createOrEdit(existing: it), icon: const Icon(Icons.edit)),
                                              IconButton(onPressed: _reordering ? null : () => _delete(it), icon: const Icon(Icons.delete_outline)),
                                              ReorderableDragStartListener(index: i, enabled: !_reordering, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.drag_handle))),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(onPressed: () => _createOrEdit(), icon: const Icon(Icons.add), label: const Text('Naujas šablonas')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
