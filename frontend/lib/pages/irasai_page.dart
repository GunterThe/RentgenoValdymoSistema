import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/irasas.dart';
import 'irasas_form_page.dart';
import 'iraso_testai_page.dart';
import '../widgets/app_scaffold.dart';

class IrasaiPage extends StatefulWidget {
  const IrasaiPage({super.key});

  @override
  State<IrasaiPage> createState() => _IrasaiPageState();
}

class _IrasaiPageState extends State<IrasaiPage> {
  List<Irasas> _items = [];
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
      final list = await Api.fetchIrasai();
      _items = list
          .map((e) => Irasas.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant įrašus: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Irasas? item}) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => IrasasFormPage(item: item)));
    if (changed == true) {
      await _load();
    }
  }

  void _addFilePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pridėti failą - dar neįgyvendinta')),
    );
  }

  void _openIrasoTestai(Irasas it) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => IrasoTestaiPage(irasas: it)));
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$y-$m-$d';
  }

  List<Irasas> _filteredAndSortedItems() {
    final q = _query.trim().toLowerCase();
    final list =
        (q.isEmpty
                ? _items
                : _items.where((e) => e.pavadinimas.toLowerCase().contains(q)))
            .toList();

    final col = _sortColumnIndex;
    if (col == null) return list;

    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    list.sort((a, b) {
      int r;
      switch (col) {
        case 0:
          r = cmp(a.pavadinimas, b.pavadinimas);
          break;
        case 1:
          r = cmp(a.idDokumento, b.idDokumento);
          break;
        case 2:
          r = a.pradzia.compareTo(b.pradzia);
          break;
        case 3:
          r = a.pabaiga.compareTo(b.pabaiga);
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
      title: 'Peržiūrėti įrašus',
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
                                    'Nėra įrašų',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
                                          label: const Text('Pavadinimas'),
                                          onSort: (i, asc) => setState(() {
                                            _sortColumnIndex = i;
                                            _sortAscending = asc;
                                          }),
                                        ),
                                        DataColumn(
                                          label: const Text('Dokumento ID'),
                                          onSort: (i, asc) => setState(() {
                                            _sortColumnIndex = i;
                                            _sortAscending = asc;
                                          }),
                                        ),
                                        DataColumn(
                                          label: const Text('Pradžia'),
                                          onSort: (i, asc) => setState(() {
                                            _sortColumnIndex = i;
                                            _sortAscending = asc;
                                          }),
                                        ),
                                        DataColumn(
                                          label: const Text('Pabaiga'),
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
                                            DataCell(Text(it.pavadinimas)),
                                            DataCell(Text(it.idDokumento)),
                                            DataCell(
                                              Text(_fmtDate(it.pradzia)),
                                            ),
                                            DataCell(
                                              Text(_fmtDate(it.pabaiga)),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        _openIrasoTestai(it),
                                                    child: const Text(
                                                      'Peržiūrėti testus',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  OutlinedButton(
                                                    onPressed:
                                                        _addFilePlaceholder,
                                                    child: const Text(
                                                      'Pridėti failą',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        _openForm(item: it),
                                                    child: const Text(
                                                      'Redaguoti',
                                                    ),
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
        icon: const Icon(Icons.add),
        label: const Text('Naujas įrašas'),
      ),
    );
  }
}
