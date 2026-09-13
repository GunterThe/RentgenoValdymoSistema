import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/prisegtas_failas.dart';
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
  final Map<int, List<PrisegtasFailas>> _failaiByRowId = {};
  final Set<int> _loadingFailaiForRow = {};

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

  String _fmtBytes(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  bool _isImageFileName(String? n) {
    if (n == null) return false;
    final lower = n.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.bmp') || lower.endsWith('.webp') || lower.endsWith('.avif') || lower.endsWith('.heic') || lower.endsWith('.heif') || lower.endsWith('.tif') || lower.endsWith('.tiff');
  }

  Future<void> _loadRowFailai(int rowId) async {
    if (_loadingFailaiForRow.contains(rowId)) return;
    setState(() => _loadingFailaiForRow.add(rowId));
    try {
      final list = await Api.fetchPrisegtiFailaiByRow(rowId);
      final items = list.map((e) => PrisegtasFailas.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() => _failaiByRowId[rowId] = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failaiByRowId[rowId] = const <PrisegtasFailas>[]);
    } finally {
      if (mounted) setState(() => _loadingFailaiForRow.remove(rowId));
    }
  }

  Future<void> _attachFileToRow(int rowId) async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: true, allowMultiple: true);
      if (res == null || res.files.isEmpty) return;

      final createdItems = <PrisegtasFailas>[];
      for (final f in res.files) {
        final fileName = f.name;
        final bytes = f.bytes;
        final path = f.path;

        final created = await Api.uploadPrisegtasFailasToRow(
          rowId: rowId,
          fileName: fileName,
          bytes: bytes,
          filePath: bytes == null ? path : null,
        );
        createdItems.add(PrisegtasFailas.fromJson(created));
      }

      if (!mounted) return;
      setState(() {
        final existing = _failaiByRowId[rowId] ?? <PrisegtasFailas>[];
        _failaiByRowId[rowId] = [...createdItems.reversed, ...existing];
      });

      final msg = createdItems.length == 1 ? 'Failas pridėtas' : 'Failai pridėti: ${createdItems.length}';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida įkeliant failą: $e')));
    }
  }

  Future<void> _deleteRowFile(PrisegtasFailas f, int rowId) async {
    try {
      await Api.deletePrisegtasFailas(f.id);
      if (!mounted) return;
      setState(() {
        _failaiByRowId[rowId] = (_failaiByRowId[rowId] ?? []).where((x) => x.id != f.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trinant failą: $e')));
    }
  }

  Future<void> _openDownload(PrisegtasFailas f) async {
    final uri = Api.prisegtasFailasDownloadUri(f.id);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openFullResImage(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nepavyko įkelti paveikslėlio'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePreview(String url) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          child: InkWell(
            onTap: () => _openFullResImage(url),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
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
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (ctx) {
                                      final rowIdVal = rowId is int ? rowId as int : int.tryParse(rowId?.toString() ?? '') ?? 0;
                                      final files = _failaiByRowId[rowIdVal] ?? const <PrisegtasFailas>[];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Failai',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              FilledButton.icon(
                                                onPressed: () => _attachFileToRow(rowIdVal),
                                                icon: const Icon(Icons.attach_file),
                                                label: const Text('Pridėti'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Atnaujinti failus',
                                                onPressed: () => _loadRowFailai(rowIdVal),
                                                icon: const Icon(Icons.refresh),
                                              ),
                                            ],
                                          ),
                                          if (_loadingFailaiForRow.contains(rowIdVal))
                                            const Padding(
                                              padding: EdgeInsets.only(top: 6),
                                              child: LinearProgressIndicator(),
                                            ),
                                          if (files.isNotEmpty)
                                            ...files
                                                .where((f) => _isImageFileName(f.failoPav))
                                                .map(
                                                  (f) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: _imagePreview(
                                                      Api.prisegtasFailasFileUri(f.id).toString(),
                                                    ),
                                                  ),
                                                ),
                                          if (files.isNotEmpty)
                                            ...files.map(
                                              (f) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(f.failoPav ?? f.id.toString()),
                                                subtitle: Text(_fmtBytes(f.dydis)),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Atsisiųsti',
                                                      onPressed: () => _openDownload(f),
                                                      icon: const Icon(Icons.download_outlined),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Pašalinti',
                                                      onPressed: () => _deleteRowFile(f, rowIdVal),
                                                      icon: const Icon(Icons.delete_outline),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          const Divider(height: 1),
                                        ],
                                      );
                                    },
                                  ),
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