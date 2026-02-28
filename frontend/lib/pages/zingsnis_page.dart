import 'package:flutter/material.dart';
import '../models/testas.dart';
import '../models/zingsnis_template.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class ZingsnisPage extends StatefulWidget {
  final Testas testas;
  const ZingsnisPage({super.key, required this.testas});

  @override
  State<ZingsnisPage> createState() => _ZingsnisPageState();
}

class _ZingsnisPageState extends State<ZingsnisPage> {
  List<ZingsnisTemplate> _items = [];
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
      final list = await Api.fetchZingsnisTemplates();
      _items = list
          .map((e) => ZingsnisTemplate.fromJson(e as Map<String, dynamic>))
          .where((t) => t.testasId == widget.testas.id)
          .toList()
        ..sort((a, b) => a.eile.compareTo(b.eile));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida kraunant žingsnius: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({ZingsnisTemplate? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.pavadinimas ?? '');
    final descCtrl = TextEditingController(text: existing?.aprasymas ?? '');

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas žingsnis' : 'Redaguoti žingsnį'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Pavadinimas')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Aprašymas')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );
    if (ok != true) return;

    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) return;

    try {
      if (existing == null) {
        final created = await Api.createZingsnisTemplate({
          'pavadinimas': title,
          'aprasymas': desc,
          'testasId': widget.testas.id,
        });
        setState(() {
          _items.add(ZingsnisTemplate.fromJson(created));
          _items.sort((a, b) => a.eile.compareTo(b.eile));
        });
      } else {
        final payload = {
          'id': existing.id,
          'pavadinimas': title,
          'aprasymas': desc,
          'testasId': widget.testas.id,
          'eile': existing.eile,
        };
        await Api.updateZingsnisTemplate(existing.id, payload);
        setState(() {
          existing.pavadinimas = title;
          existing.aprasymas = desc;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_reordering) return;
    if (oldIndex < 0 || oldIndex >= _items.length) return;

    setState(() => _reordering = true);
    try {
      // Reorder in-memory list.
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = _items.removeAt(oldIndex);
      _items.insert(newIndex, moved);

      // Persist only the moved item's new position; backend will shift others.
      final newEile = newIndex + 1;
      final payload = {
        'id': moved.id,
        'pavadinimas': moved.pavadinimas,
        'aprasymas': moved.aprasymas,
        'testasId': moved.testasId,
        'eile': newEile,
      };
      await Api.updateZingsnisTemplate(moved.id, payload);

      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida rikiuojant: $e')));
      await _load();
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _delete(ZingsnisTemplate it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti žingsnį?'),
        content: Text('Ar tikrai ištrinti "${it.pavadinimas}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteZingsnisTemplate(it.id);
      setState(() => _items.removeWhere((e) => e.id == it.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Žingsniai: ${widget.testas.testotekstas}',
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
                              ? Center(
                                  child: Text('Nėra žingsnių', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                )
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
                                          title: Text('${it.eile}. ${it.pavadinimas}'),
                                          subtitle: Text(it.aprasymas),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: _reordering ? null : () => _createOrEdit(existing: it),
                                                icon: const Icon(Icons.edit),
                                              ),
                                              IconButton(
                                                onPressed: _reordering ? null : () => _delete(it),
                                                icon: const Icon(Icons.delete_outline),
                                              ),
                                              ReorderableDragStartListener(
                                                index: i,
                                                enabled: !_reordering,
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                                  child: Icon(Icons.drag_handle),
                                                ),
                                              ),
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
                          child: FilledButton.icon(
                            onPressed: () => _createOrEdit(),
                            icon: const Icon(Icons.add),
                            label: const Text('Naujas žingsnis'),
                          ),
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
