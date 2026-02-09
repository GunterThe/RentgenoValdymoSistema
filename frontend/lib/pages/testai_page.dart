import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/testas.dart';
import 'testas_form_page.dart';
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
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Api.fetchTestai();
      _items = list.map((e) => Testas.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida kraunant testus: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Testas? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TestasFormPage(item: item)),
    );
    if (changed == true) {
      await _load();
    }
  }

  void _showChangesPlaceholder(Testas it) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peržiūrėti pakeitimus - dar neįgyvendinta')),
    );
  }

  List<Testas> _filteredAndSortedItems() {
    final q = _query.trim().toLowerCase();
    final list = (q.isEmpty
            ? _items
            : _items.where((e) => e.testotekstas.toLowerCase().contains(q)))
        .toList();

    final col = _sortColumnIndex;
    if (col == null) return list;

    list.sort((a, b) {
      int r;
      switch (col) {
        case 0:
          r = a.testotekstas.toLowerCase().compareTo(b.testotekstas.toLowerCase());
          break;
        default:
          r = 0;
      }
      return _sortAscending ? r : -r;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filteredAndSortedItems();
    return AppScaffold(
      title: 'Peržiūrėti testus',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        )
      ],
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(
                                          label: const Text('Tekstas'),
                                          onSort: (i, asc) => setState(() {
                                            _sortColumnIndex = i;
                                            _sortAscending = asc;
                                          }),
                                        ),
                                        const DataColumn(
                                          label: Text('Veiksmai'),
                                        ),
                                      ],
                                      rows: shown.map((it) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(it.testotekstas)),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        _showChangesPlaceholder(it),
                                                    child: const Text(
                                                        'Peržiūrėti pakeitimus'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        _openForm(item: it),
                                                    child:
                                                        const Text('Redaguoti'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Naujas testas'),
      ),
    );
  }
}
