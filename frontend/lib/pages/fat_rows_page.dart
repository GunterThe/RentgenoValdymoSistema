import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';
import 'row_columns_page.dart';

class FatRowsPage extends StatefulWidget {
  final int fatId;
  final String fatTitle;
  const FatRowsPage({super.key, required this.fatId, required this.fatTitle});

  @override
  State<FatRowsPage> createState() => _FatRowsPageState();
}

class _FatRowsPageState extends State<FatRowsPage> {
  List<Map<String, dynamic>> _allRows = [];
  List<Map<String, dynamic>> _fatRows = [];
  bool _loading = true;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _editRow(Map<String, dynamic> row) async {
    final descCtrl = TextEditingController(text: (row['description'] ?? '') as String);
    final methodsCtrl = TextEditingController(text: (row['controlMethods'] ?? '') as String);

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redaguoti eilutę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Aprašymas')),
            const SizedBox(height: 8),
            TextField(controller: methodsCtrl, decoration: const InputDecoration(labelText: 'Kontrolės metodai')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final payload = {
        'id': row['id'] as int,
        'description': descCtrl.text.trim(),
        'controlMethods': methodsCtrl.text.trim(),
        'rowValueId': (row['rowValueId'] ?? 0) as int,
      };
      await Api.updateRow(row['id'] as int, payload);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida atnaujinant: $e')));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await Api.fetchRows();
      final fatrows = await Api.fetchFATRows();
      _allRows = (rows).map((e) => e as Map<String, dynamic>).toList();
      _fatRows =
          (fatrows)
              .map((e) => e as Map<String, dynamic>)
              .where((e) => (e['fatid'] as int) == widget.fatId)
              .toList()
            ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addRow() async {
    final newCtrl = TextEditingController();
    final ctrlMethods = TextEditingController();

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pridėti eilutę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newCtrl,
              decoration: const InputDecoration(
                labelText: 'Naujos eilutės aprašymas',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrlMethods,
              decoration: const InputDecoration(labelText: 'Kontrolės metodai'),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Atšaukti'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pridėti'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      int rowId;
      final text = newCtrl.text.trim();
      if (text.isNotEmpty) {
      final created = await Api.createRow({
        'description': text,
        'controlMethods': ctrlMethods.text.trim(),
        'rowValueId': 0,
      });
      rowId = created['id'] as int;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nurodykite aprašymą arba pasirinkite eilutę'),
        ),
      );
      return;
    }

      

      await Api.createFATRow({
        'fatid': widget.fatId,
        'rowid': rowId,
        'order': 0,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _removeRow(Map<String, dynamic> fatRow) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti eilutę iš FAT?'),
        content: Text('Ar tikrai pašalinti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Taip'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteFATRow(widget.fatId, fatRow['rowid'] as int);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }


  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_reordering) return;
    if (oldIndex < 0 || oldIndex >= _fatRows.length) return;

    setState(() => _reordering = true);
    try {
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = _fatRows.removeAt(oldIndex);
      _fatRows.insert(newIndex, moved);

      final newOrder = newIndex + 1;
      await Api.updateFATRowOrder(
        moved['fatid'] as int,
        moved['rowid'] as int,
        {'order': newOrder},
      );

      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida rikiuojant: $e')));
      await _load();
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  String _rowDesc(int id) {
    final r = _allRows.firstWhere(
      (e) => (e['id'] as int) == id,
      orElse: () => {} as Map<String, dynamic>,
    );
    return (r['description'] ?? '') as String;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'FAT: ${widget.fatTitle}',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRow,
        icon: const Icon(Icons.add),
        label: const Text('Pridėti eilutę'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _fatRows.isEmpty
                        ? Center(
                            child: Text(
                              'Nėra eilučių',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: _onReorder,
                            itemCount: _fatRows.length,
                            itemBuilder: (ctx, index) {
                              final fr = _fatRows[index];
                              final rowId = fr['rowid'] as int;
                              final order = fr['order'] as int;
                              final row = _allRows.firstWhere(
                                (r) => (r['id'] as int) == rowId,
                                orElse: () => {} as Map<String, dynamic>,
                              );
                              return Column(
                                key: ValueKey('${fr['fatid']}-${fr['rowid']}'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text(
                                      (row['description'] ?? _rowDesc(rowId))
                                          as String,
                                    ),
                                    subtitle: Text('Eilė: $order'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _editRow(
                                            row.isNotEmpty
                                                ? row
                                                : {
                                                    'id': rowId,
                                                    'description': _rowDesc(
                                                      rowId,
                                                    ),
                                                    'controlMethods': '',
                                                  },
                                          ),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeRow(fr),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RowColumnsPage(
                                                rowId: rowId,
                                                rowDesc: (row['description'] ?? _rowDesc(rowId)) as String,
                                              ),
                                            ),
                                          ),
                                          icon: const Icon(Icons.view_column),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          enabled: !_reordering,
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
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
            ),
    );
  }
}
