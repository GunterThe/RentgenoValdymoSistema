import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class IrasasColumnPage extends StatefulWidget {
  final Irasas irasas;

  const IrasasColumnPage({super.key, required this.irasas});

  @override
  State<IrasasColumnPage> createState() => _IrasasColumnPageState();
}

class _IrasasColumnPageState extends State<IrasasColumnPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rowIrasai = [];
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _columnTemplates = [];
  List<Map<String, dynamic>> _columnValues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.fetchRowIrasai(),
        Api.fetchRows(),
        Api.fetchColumnTemplates(),
        Api.fetchColumnValues(),
      ]);

      final rowIrasai = (results[0] as List).map((e) => e as Map<String, dynamic>).toList();
      final rows = (results[1] as List).map((e) => e as Map<String, dynamic>).toList();
      final templates = (results[2] as List).map((e) => e as Map<String, dynamic>).toList();
      final values = (results[3] as List).map((e) => e as Map<String, dynamic>).toList();

      setState(() {
        _rowIrasai = rowIrasai.where((r) => (r['irasasId'] ?? r['irasasid'] ?? r['irasas_id']) == widget.irasas.id).toList();
        _rowIrasai.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
        _rows = rows;
        _columnTemplates = templates;
        _columnValues = values;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida kraunant FAT: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attachFat() async {
    try {
      final fats = await Api.fetchFATs();
      int? selectedId;
      if (!mounted) return;
      final ok = await showDialog<bool?>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Pridėti FAT šabloną'),
            content: SizedBox(
              width: 560,
              child: ListView(
                shrinkWrap: true,
                children: fats.map<Widget>((f) {
                  final fm = f as Map<String, dynamic>;
                  return RadioListTile<int>(
                    value: fm['id'] as int,
                    groupValue: selectedId,
                    title: Text(fm['title'] ?? fm['Title'] ?? 'FAT #${fm['id']}'),
                    onChanged: (v) => setLocal(() => selectedId = v),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Pridėti')),
            ],
          ),
        ),
      );

      if (ok != true || selectedId == null) return;
      await Api.attachFATTemplateToIrasas(widget.irasas.id, selectedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAT pridėtas')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida pridedant FAT: $e')));
    }
  }

  String _formatValue(Map<String, dynamic>? value, Map<String, dynamic> template) {
    if (value == null) return '-';
    final isArray = template['isArray'] ?? template['is_array'] ?? template['isArray'] ?? false;
    if (isArray == true || isArray == 1) {
      final arr = value['arrayValue'] ?? value['array_value'] ?? value['arrayValue'];
      if (arr == null) return '-';
      return (arr as List).join(', ');
    }
    final single = value['singleValue'] ?? value['single_value'] ?? value['singleValue'];
    if (single == null) return '-';
    return single.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Peržiūrėti FAT',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _rowIrasai.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.irasas.pavadinimas,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text('Šitam įrašui nėra FAT eilučių. Pridėkite FAT šabloną.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _attachFat,
                            child: const Text('Pridėti FAT šabloną'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _rowIrasai.length,
                        itemBuilder: (ctx, index) {
                          final r = _rowIrasai[index];
                          final rowDef = _rows.firstWhere(
                            (x) => (x['id'] ?? x['Id']) == (r['rowId'] ?? r['rowid'] ?? r['row_id']),
                            orElse: () => <String, dynamic>{'description': 'Eilutė #${r['rowId'] ?? r['rowid'] ?? '?'}'},
                          );

                          final templates = _columnTemplates.where((t) => (t['rowId'] ?? t['row_id'] ?? t['RowId']) == (rowDef['id'] ?? rowDef['Id'])).toList();
                          templates.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rowDef['description'] ?? rowDef['Description'] ?? 'Eilutė', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  ...templates.map((tpl) {
                                    final val = _columnValues.firstWhere(
                                      (v) => (v['rowIrasasId'] ?? v['row_irasas_id'] ?? v['RowIrasasId']) == (r['id'] ?? r['Id']) && (v['columnTemplateId'] ?? v['column_template_id'] ?? v['ColumnTemplateId']) == (tpl['id'] ?? tpl['Id']),
                                      orElse: () => <String, dynamic>{},
                                    );
                                    final valueMap = val.isEmpty ? null : val as Map<String, dynamic>?;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(tpl['description'] ?? tpl['Description'] ?? 'Stulpelis #${tpl['id'] ?? tpl['Id']}'),
                                      subtitle: Text(_formatValue(valueMap, tpl)),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
