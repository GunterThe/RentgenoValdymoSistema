import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class RowColumnsPage extends StatefulWidget {
  final int rowId;
  final String rowDesc;
  const RowColumnsPage({super.key, required this.rowId, required this.rowDesc});

  @override
  State<RowColumnsPage> createState() => _RowColumnsPageState();
}

class _RowColumnsPageState extends State<RowColumnsPage> {
  List<Map<String, dynamic>> _headers = [];
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  bool _readBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is int) return v != 0;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await Api.fetchHeaders();
      final templates = await Api.fetchColumnTemplates();
      _headers = (headers).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final mapped = (templates).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      int? getRowId(Map<String, dynamic> t) {
        final v = t['rowId'] ?? t['row_id'] ?? t['RowId'];
        if (v == null) return null;
        return v is int ? v : int.tryParse(v.toString());
      }
      _templates = mapped.where((t) => (getRowId(t) ?? 0) == widget.rowId).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida2: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createHeader() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nauja antraštė'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Text')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sukurti')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.createHeader(ctrl.text.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _editHeader(Map<String, dynamic> header) async {
    final ctrl = TextEditingController(text: (header['text'] ?? '') as String);
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redaguoti antraštę'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Text')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = _parseInt(header['id']) ?? 0;
      await Api.updateHeader(id, ctrl.text.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _deleteHeader(int id) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti antraštę?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteHeader(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _createTemplate({int? headerId, Map<String, dynamic>? existing}) async {
    final descCtrl = TextEditingController(text: existing == null ? '' : (existing['description'] ?? '') as String);
    var isArray = existing == null ? false : _readBool(existing['is_array'] ?? existing['isArray']);
    var arrayCount = existing == null ? 2 : (_parseInt(existing['array_count'] ?? existing['arrayCount']) ?? 2);
    final arrayCtrl = TextEditingController(text: '$arrayCount');
    int? selectedHeader = headerId ?? (existing == null ? null : _parseInt(existing['header_id'] ?? existing['headerId']));

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas stulpelio šablonas' : 'Redaguoti stulpelio šabloną'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Aprašymas')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedHeader,
                items: _headers.map((h) => DropdownMenuItem<int>(value: _parseInt(h['id']) ?? 0, child: Text((h['text'] ?? '') as String))).toList(),
                onChanged: (v) => setState(() => selectedHeader = v),
                decoration: const InputDecoration(labelText: 'Antraštė'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Ar masyvas?'),
                value: isArray,
                onChanged: (v) => setState(() => isArray = v),
              ),
              if (isArray) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Kiek elementų:'),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: arrayCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: '2'),
                        onChanged: (v) => setState(() => arrayCount = int.tryParse(v) ?? 2),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final desc = descCtrl.text.trim();
      if (desc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aprašymas yra būtinas')));
        return;
      }

      final payload = <String, dynamic>{
        'description': desc,
        'rowId': widget.rowId,
        'isArray': isArray,
        'order': existing == null ? 0 : (_parseInt(existing['order']) ?? 0),
      };
      if (selectedHeader != null) payload['headerId'] = selectedHeader;
      if (isArray) {
        final parsed = int.tryParse(arrayCtrl.text) ?? arrayCount;
        payload['arrayLength'] = parsed; // backend expects ArrayLength
      }
      if (existing != null) payload['id'] = _parseInt(existing['id']) ?? 0;

      if (existing == null) {
        await Api.createColumnTemplate(payload);
      } else {
        await Api.updateColumnTemplate(_parseInt(existing['id']) ?? 0, payload);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _deleteTemplate(int id) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti šabloną?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteColumnTemplate(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Stulpeliai: ${widget.rowDesc}',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTemplate,
        icon: const Icon(Icons.add),
        label: const Text('Naujas šablonas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _createHeader,
                            icon: const Icon(Icons.note_add),
                            label: const Text('Sukurti antraštę'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _templates.isEmpty && _headers.isEmpty
                              ? Center(
                                  child: Text('Nėra šablonų', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                )
                              : Builder(
                                  builder: (ctx) {
                                    // group templates by header id (nullable)
                                    final Map<int?, List<Map<String, dynamic>>> grouped = {};
                                    for (var t in _templates) {
                                      final hid = _parseInt(t['header_id'] ?? t['headerId']);
                                      grouped.putIfAbsent(hid, () => []).add(t);
                                    }

                                    final List<Widget> children = [];

                                    // render headers and their templates
                                    for (var h in _headers) {
                                      final hid = _parseInt(h['id']) ?? -1;
                                      final templatesForHeader = grouped[hid] ?? [];
                                      children.add(
                                        Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Theme.of(context).colorScheme.surface,
                                          ),
                                          child: ExpansionTile(
                                            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                                            title: Row(children: [
                                              Expanded(child: Text((h['text'] ?? '') as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                                              IconButton(onPressed: () => _editHeader(h), icon: const Icon(Icons.edit)),
                                              IconButton(onPressed: () => _deleteHeader(hid), icon: const Icon(Icons.delete_outline)),
                                            ]),
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ReorderableListView(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                onReorder: (oldIndex, newIndex) async {
                                                  if (oldIndex < newIndex) newIndex -= 1;
                                                  setState(() {
                                                    final item = templatesForHeader.removeAt(oldIndex);
                                                    templatesForHeader.insert(newIndex, item);
                                                  });

                                                  // update orders sequentially (1-based)
                                                  for (var i = 0; i < templatesForHeader.length; i++) {
                                                    final t = templatesForHeader[i];
                                                    final id = _parseInt(t['id']) ?? 0;
                                                    final payload = <String, dynamic>{
                                                      'id': id,
                                                      'description': t['description'] ?? '',
                                                      'rowId': widget.rowId,
                                                      'isArray': _readBool(t['is_array'] ?? t['isArray']),
                                                      'order': i + 1,
                                                    };
                                                    final hid = _parseInt(t['header_id'] ?? t['headerId']);
                                                    if (hid != null) payload['headerId'] = hid;
                                                    if (t.containsKey('array_length') || t.containsKey('arrayLength')) {
                                                      payload['arrayLength'] = _parseInt(t['array_length'] ?? t['arrayLength']) ?? 0;
                                                    }
                                                    try {
                                                      await Api.updateColumnTemplate(id, payload);
                                                    } catch (e) {
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida atnaujinant eiles: $e')));
                                                      return;
                                                    }
                                                  }
                                                  await _load();
                                                },
                                                children: templatesForHeader.map((t) {
                                                  final key = ValueKey('tpl_${_parseInt(t['id']) ?? UniqueKey()}');
                                                  final isArray = _readBool(t['is_array'] ?? t['isArray']);
                                                  return ListTile(
                                                    key: key,
                                                    contentPadding: const EdgeInsets.only(left: 24, right: 16),
                                                    title: Text((t['description'] ?? '') as String),
                                                    subtitle: Text('${isArray ? 'Masyvas' : 'Vienas skaičius'} • Eilės nr ${t['order'] ?? ''}'),
                                                    trailing: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(onPressed: () => _createTemplate(existing: t), icon: const Icon(Icons.edit)),
                                                        IconButton(onPressed: () => _deleteTemplate(_parseInt(t['id']) ?? 0), icon: const Icon(Icons.delete_outline)),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          ],
                                          ),
                                        ),
                                      );
                                    }

                                    // templates without header
                                    final headerless = grouped[null] ?? grouped[-1] ?? [];
                                    if (headerless.isNotEmpty) {
                                      children.add(const Divider());
                                      children.add(const ListTile(title: Text('Be antraštės', style: TextStyle(fontWeight: FontWeight.bold))));
                                      if (headerless.isNotEmpty) {
                                        // allow reordering of headerless templates
                                        children.add(
                                          SizedBox(
                                            child: ReorderableListView(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              onReorder: (oldIndex, newIndex) async {
                                                final templatesForHeader = headerless;
                                                if (oldIndex < newIndex) newIndex -= 1;
                                                setState(() {
                                                  final item = templatesForHeader.removeAt(oldIndex);
                                                  templatesForHeader.insert(newIndex, item);
                                                });

                                                for (var i = 0; i < templatesForHeader.length; i++) {
                                                  final t = templatesForHeader[i];
                                                  final id = _parseInt(t['id']) ?? 0;
                                                  final payload = <String, dynamic>{
                                                    'id': id,
                                                    'description': t['description'] ?? '',
                                                    'rowId': widget.rowId,
                                                    'isArray': _readBool(t['is_array'] ?? t['isArray']),
                                                    'order': i + 1,
                                                  };
                                                  final hid = _parseInt(t['header_id'] ?? t['headerId']);
                                                  if (hid != null) payload['headerId'] = hid;
                                                  if (t.containsKey('array_length') || t.containsKey('arrayLength')) {
                                                    payload['arrayLength'] = _parseInt(t['array_length'] ?? t['arrayLength']) ?? 0;
                                                  }
                                                  try {
                                                    await Api.updateColumnTemplate(id, payload);
                                                  } catch (e) {
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida atnaujinant eiles: $e')));
                                                    return;
                                                  }
                                                }
                                                await _load();
                                              },
                                              children: headerless.map((t) {
                                                final key = ValueKey('tpl_${_parseInt(t['id']) ?? UniqueKey()}');
                                                final isArray = _readBool(t['is_array'] ?? t['isArray']);
                                                return ListTile(
                                                  key: key,
                                                  contentPadding: const EdgeInsets.only(left: 24, right: 16),
                                                  title: Text((t['description'] ?? '') as String),
                                                  subtitle: Text('${isArray ? 'Masyvas' : 'Vienas skaičius'} • Eilės nr ${t['order'] ?? ''}'),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(onPressed: () => _createTemplate(existing: t), icon: const Icon(Icons.edit)),
                                                      IconButton(onPressed: () => _deleteTemplate(_parseInt(t['id']) ?? 0), icon: const Icon(Icons.delete_outline)),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    return ListView(children: children);
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
