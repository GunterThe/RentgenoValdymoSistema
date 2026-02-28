import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/irasas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
import 'irasas_zingsniai_page.dart';
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

  Future<void> _editIrasas(Irasas it) async {
    final idDocCtrl = TextEditingController(text: it.idDokumento);
    final pavCtrl = TextEditingController(text: it.pavadinimas);
    var pradzia = it.pradzia;
    var pabaiga = it.pabaiga;

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Redaguoti įrašą'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pavCtrl,
                decoration: const InputDecoration(labelText: 'Pavadinimas'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: idDocCtrl,
                decoration: const InputDecoration(labelText: 'Dokumento ID'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: pradzia,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pradzia = DateTime(picked.year, picked.month, picked.day);
                          if (pabaiga.isBefore(pradzia)) pabaiga = pradzia;
                        });
                      },
                      child: Text('Pradžia: ${_fmtDate(pradzia)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: pabaiga,
                          firstDate: pradzia,
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pabaiga = DateTime(picked.year, picked.month, picked.day);
                        });
                      },
                      child: Text('Pabaiga: ${_fmtDate(pabaiga)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Išsaugoti'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final payload = {
      'id': it.id,
      'pavadinimas': pavCtrl.text.trim(),
      'idDokumento': idDocCtrl.text.trim(),
      'pradzia': pradzia.toUtc().toIso8601String(),
      'pabaiga': pabaiga.toUtc().toIso8601String(),
    };

    try {
      await Api.updateIrasas(it.id, payload);
      if (!mounted) return;
      setState(() {
        it.pavadinimas = payload['pavadinimas'] as String;
        it.idDokumento = payload['idDokumento'] as String;
        it.pradzia = pradzia;
        it.pabaiga = pabaiga;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Įrašas išsaugotas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _createIrasas() async {
    final idDocCtrl = TextEditingController();
    final pavCtrl = TextEditingController();
    var pradzia = DateTime.now();
    var pabaiga = DateTime.now();

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Naujas įrašas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pavCtrl,
                decoration: const InputDecoration(labelText: 'Pavadinimas'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: idDocCtrl,
                decoration: const InputDecoration(labelText: 'Dokumento ID'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: pradzia,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pradzia = DateTime(picked.year, picked.month, picked.day);
                          if (pabaiga.isBefore(pradzia)) pabaiga = pradzia;
                        });
                      },
                      child: Text('Pradžia: ${_fmtDate(pradzia)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: pabaiga,
                          firstDate: pradzia,
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pabaiga = DateTime(picked.year, picked.month, picked.day);
                        });
                      },
                      child: Text('Pabaiga: ${_fmtDate(pabaiga)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sukurti'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final payload = {
      'pavadinimas': pavCtrl.text.trim(),
      'idDokumento': idDocCtrl.text.trim(),
      'pradzia': pradzia.toUtc().toIso8601String(),
      'pabaiga': pabaiga.toUtc().toIso8601String(),
    };

    if ((payload['pavadinimas'] as String).isEmpty ||
        (payload['idDokumento'] as String).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Užpildykite pavadinimą ir dokumento ID')),
      );
      return;
    }

    try {
      final created = await Api.createIrasas(payload);
      final it = Irasas.fromJson(created);
      if (!mounted) return;
      setState(() => _items.add(it));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Įrašas sukurtas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _addTestToIrasas(Irasas it) async {
    try {
      final results = await Future.wait([
        Api.fetchTestai(),
        Api.fetchTestasIrasai(),
      ]);

        final testai = (results[0])
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
        final links = (results[1])
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .where((l) => l.irasasId == it.id)
          .toList();
      final used = links.map((e) => e.testasId).toSet();

      final available = testai.where((t) => !used.contains(t.id)).toList();
      if (available.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nėra laisvų testų pridėjimui')),
        );
        return;
      }

      Testas selected = available.first;

      final ok = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pridėti testą'),
          content: DropdownButtonFormField<int>(
            initialValue: selected.id,
            items: available
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.testotekstas),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              selected = available.firstWhere((t) => t.id == v);
            },
            decoration: const InputDecoration(labelText: 'Testas'),
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

      await Api.createTestasIrasas({
        'testasid': selected.id,
        'irasasid': it.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testas pridėtas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _removeTestFromIrasas(Irasas it) async {
    try {
      final results = await Future.wait([
        Api.fetchTestai(),
        Api.fetchTestasIrasai(),
      ]);

      final testai = (results[0])
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
      final links = (results[1])
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .where((l) => l.irasasId == it.id)
          .toList();

      final linkedTestIds = links.map((e) => e.testasId).toSet();
      final linkedTests = testai.where((t) => linkedTestIds.contains(t.id)).toList();

      if (linkedTests.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Šitam įrašui nėra pridėtų testų')),
        );
        return;
      }

      Testas selected = linkedTests.first;

      final ok = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pašalinti testą'),
          content: DropdownButtonFormField<int>(
            initialValue: selected.id,
            items: linkedTests
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.testotekstas),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              selected = linkedTests.firstWhere((t) => t.id == v);
            },
            decoration: const InputDecoration(labelText: 'Testas'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Pašalinti'),
            ),
          ],
        ),
      );

      if (ok != true) return;

      final link = links.firstWhere(
        (l) => l.testasId == selected.id,
        orElse: () => throw Exception('Ryšys nerastas'),
      );

      await Api.deleteTestasIrasasById(link.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testas pašalintas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _deleteIrasas(Irasas it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti įrašą?'),
        content: Text('Ar tikrai ištrinti "${it.pavadinimas}"?'),
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
      await Api.deleteIrasas(it.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createIrasas(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Naujas įrašas'),
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
                                            DataCell(Row(
                                              children: [
                                                IconButton(
                                                  tooltip: 'Peržiūrėti',
                                                  onPressed: () => showPlaceholder(context, 'Peržiūrėti įrašą'),
                                                  icon: const Icon(Icons.remove_red_eye_outlined),
                                                ),
                                                IconButton(
                                                  tooltip: 'Redaguoti',
                                                  onPressed: () => _editIrasas(it),
                                                  icon: const Icon(Icons.edit),
                                                ),
                                                IconButton(
                                                  tooltip: 'Pridėti testą',
                                                  onPressed: () => _addTestToIrasas(it),
                                                  icon: const Icon(Icons.playlist_add),
                                                ),
                                                IconButton(
                                                  tooltip: 'Pašalinti testą',
                                                  onPressed: () => _removeTestFromIrasas(it),
                                                  icon: const Icon(Icons.playlist_remove),
                                                ),
                                                IconButton(
                                                  tooltip: 'Žingsniai',
                                                  onPressed: () => Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => IrasasZingsniaiPage(irasas: it),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.format_list_numbered),
                                                ),
                                                IconButton(
                                                  tooltip: 'Ištrinti',
                                                  onPressed: () => _deleteIrasas(it),
                                                  icon: const Icon(Icons.delete_outline),
                                                ),
                                              ],
                                            )),
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
    );
  }
}
