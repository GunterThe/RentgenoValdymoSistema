import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/testas.dart';
import 'zingsnis_page.dart';
import '../widgets/app_scaffold.dart';

class TestaiPage extends StatefulWidget {
  const TestaiPage({super.key});

  @override
  State<TestaiPage> createState() => _TestaiPageState();
}

class _TestaiPageState extends State<TestaiPage> {
  List<Testas> _items = [];
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
      final list = await Api.fetchTestai();
      _items = list
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida kraunant testus: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({Testas? existing}) async {
    final ctrl = TextEditingController(text: existing?.testotekstas ?? '');
    String? tipas = existing?.tipas ?? 'Testas';

    int? _tipasToIndex(String? t) {
      if (t == null) return null;
      switch (t) {
        case 'Testas':
          return 0;
        case 'Isvezimas':
          return 1;
        case 'Pakavimas':
          return 2;
        default:
          return int.tryParse(t);
      }
    }

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Naujas testas' : 'Redaguoti testą'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Testo tekstas'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: tipas,
              items: const [
                DropdownMenuItem(value: 'Testas', child: Text('Testas')),
                DropdownMenuItem(value: 'Isvezimas', child: Text('Išvežimas')),
                DropdownMenuItem(value: 'Pakavimas', child: Text('Pakavimas')),
              ],
              onChanged: (v) => tipas = v,
              decoration: const InputDecoration(labelText: 'Tipas'),
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
        final created = await Api.createTestas({
          'testotekstas': text,
          'tipas': _tipasToIndex(tipas),
        });
        setState(() {
          _items.add(Testas.fromJson(created));
        });
      } else {
        final payload = {
          'id': existing.id,
          'testotekstas': text,
          'tipas': _tipasToIndex(tipas),
        };
        await Api.updateTestas(existing.id, payload);
        setState(() {
          existing.testotekstas = text;
          existing.tipas = tipas;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(Testas it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti testą?'),
        content: Text('Ar tikrai ištrinti "${it.testotekstas}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Taip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteTestas(it.id);
      setState(() => _items.removeWhere((e) => e.id == it.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  List<Testas> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) => e.testotekstas.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filtered();
    return AppScaffold(
      title: 'Testai',
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
        label: const Text('Naujas testas'),
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
                        labelText: 'Paieška pagal tekstą',
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
                                    'Nėra testų',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Tekstas')),
                                        DataColumn(label: Text('Tipas')),
                                        DataColumn(label: Text('Veiksmai')),
                                      ],
                                      rows: shown.map((it) {
                                        return DataRow(cells: [
                                          DataCell(Text(it.testotekstas)),
                                          DataCell(Text(it.tipas ?? '')), 
                                          DataCell(Row(
                                            children: [
                                              IconButton(
                                                tooltip: 'Redaguoti',
                                                onPressed: () => _createOrEdit(existing: it),
                                                icon: const Icon(Icons.edit),
                                              ),
                                              IconButton(
                                                tooltip: 'Žingsniai',
                                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                                  builder: (_) => ZingsnisPage(testas: it),
                                                )),
                                                icon: const Icon(Icons.format_list_numbered),
                                              ),
                                              IconButton(
                                                tooltip: 'Ištrinti',
                                                onPressed: () => _delete(it),
                                                icon: const Icon(Icons.delete_outline),
                                              ),
                                            ],
                                          )),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
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
