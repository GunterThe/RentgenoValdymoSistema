import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';
import 'package:web/web.dart' as web;
import 'fat_rows_page.dart';

class FatItem {
  int id;
  String title;
  FatItem({required this.id, required this.title});

  factory FatItem.fromJson(Map<String, dynamic> json) => FatItem(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
      );
}

class FatPage extends StatefulWidget {
  const FatPage({super.key});

  @override
  State<FatPage> createState() => _FatPageState();
}

class _FatPageState extends State<FatPage> {
  List<FatItem> _items = [];
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
      final list = await Api.fetchFATs();
      _items = list
          .map((e) => FatItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida kraunant FAT: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({FatItem? existing}) async {
    final ctrl = TextEditingController(text: existing?.title ?? '');

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas FAT' : 'Redaguoti FAT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Pavadinimas'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Išsaugoti'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final text = ctrl.text.trim();
    try {
      if (existing == null) {
        final created = await Api.createFAT(title: text);
        setState(() {
          _items.add(FatItem.fromJson(created));
        });
      } else {
        final payload = {'id': existing.id, 'title': text};
        await Api.updateFAT(existing.id, payload);
        setState(() {
          existing.title = text;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(FatItem it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti FAT?'),
        content: Text('Ar tikrai ištrinti "${it.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteFAT(it.id);
      setState(() => _items.removeWhere((e) => e.id == it.id));
      web.window.location.reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  List<FatItem> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) => e.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filtered();
    return AppScaffold(
      title: 'FAT',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Naujas FAT'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Paieška pagal pavadinimą',
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: shown.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nėra FAT',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 700;

                                    if (isNarrow) {
                                      return ListView.separated(
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
                                                  Text(
                                                    it.title,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    alignment: WrapAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Redaguoti',
                                                        onPressed: () => _createOrEdit(existing: it),
                                                        icon: const Icon(Icons.edit),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Eilutės',
                                                        onPressed: () => Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) => FatRowsPage(fatId: it.id, fatTitle: it.title),
                                                          ),
                                                        ),
                                                        icon: const Icon(Icons.format_list_numbered),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Ištrinti',
                                                        onPressed: () => _delete(it),
                                                        icon: const Icon(Icons.delete_outline),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('Pavadinimas')),
                                            DataColumn(label: Text('Veiksmai')),
                                          ],
                                          rows: shown.map((it) {
                                            return DataRow(
                                              cells: [
                                                DataCell(Text(it.title)),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Redaguoti',
                                                        onPressed: () => _createOrEdit(existing: it),
                                                        icon: const Icon(Icons.edit),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Eilutės',
                                                        onPressed: () => Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) => FatRowsPage(fatId: it.id, fatTitle: it.title),
                                                          ),
                                                        ),
                                                        icon: const Icon(Icons.format_list_numbered),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Ištrinti',
                                                        onPressed: () => _delete(it),
                                                        icon: const Icon(Icons.delete_outline),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
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
