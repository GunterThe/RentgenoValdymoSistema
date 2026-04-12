import 'package:flutter/material.dart';

import '../models/sablonas.dart';
import '../models/testas.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class SablonaiPage extends StatefulWidget {
  const SablonaiPage({super.key});

  @override
  State<SablonaiPage> createState() => _SablonaiPageState();
}

class _SablonaiPageState extends State<SablonaiPage> {
  List<Sablonas> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Api.fetchSablonai();
      final items = list
          .map((e) => Sablonas.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort(
        (a, b) =>
            a.pavadinimas.toLowerCase().compareTo(b.pavadinimas.toLowerCase()),
      );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant šablonus: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({Sablonas? existing}) async {
    final ctrl = TextEditingController(text: existing?.pavadinimas ?? '');

    List<Testas> testai = const <Testas>[];
    Set<int> initialSelected = <int>{};

    try {
      final results = await Future.wait([
        Api.fetchTestai(),
        Api.fetchSablonasTestai(),
      ]);

      testai = (results[0])
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
      testai.sort(
        (a, b) => a.testotekstas.toLowerCase().compareTo(
          b.testotekstas.toLowerCase(),
        ),
      );

      final links = (results[1]).cast<dynamic>();
      if (existing != null) {
        final selected = <int>{};
        for (final raw in links) {
          if (raw is! Map<String, dynamic>) continue;
          final sid =
              (raw['sablonasid'] ??
              raw['Sablonasid'] ??
              raw['sablonasId'] ??
              raw['SablonasId']);
          final tid =
              (raw['testasid'] ??
              raw['Testasid'] ??
              raw['testasId'] ??
              raw['TestasId']);
          if (sid is int && tid is int && sid == existing.id) selected.add(tid);
        }
        initialSelected = selected;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant testus: $e')));
      return;
    }

    final selectedTestIds = <int>{...initialSelected};

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Naujas šablonas' : 'Redaguoti šabloną',
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Pavadinimas'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Testai',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (testai.isNotEmpty)
                      Text(
                        '${selectedTestIds.length}/${testai.length}',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (testai.isEmpty)
                  Text(
                    'Nėra testų',
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: testai.length,
                        itemBuilder: (ctx, index) {
                          final t = testai[index];
                          final checked = selectedTestIds.contains(t.id);
                          return CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: checked,
                            title: Text(t.testotekstas),
                            onChanged: (v) {
                              setLocal(() {
                                final next = v ?? false;
                                if (next) {
                                  selectedTestIds.add(t.id);
                                } else {
                                  selectedTestIds.remove(t.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Išsaugoti'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final name = ctrl.text.trim();
    try {
      if (existing == null) {
        final created = await Api.createSablonas({'pavadinimas': name});
        final it = Sablonas.fromJson(created);

        for (final testasId in selectedTestIds) {
          await Api.createSablonasTestas({
            'sablonasid': it.id,
            'testasid': testasId,
          });
        }

        if (!mounted) return;
        setState(() {
          _items.add(it);
          _items.sort(
            (a, b) => a.pavadinimas.toLowerCase().compareTo(
              b.pavadinimas.toLowerCase(),
            ),
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Šablonas sukurtas')));
      } else {
        await Api.updateSablonas(existing.id, {
          'id': existing.id,
          'pavadinimas': name,
        });

        final toAdd = selectedTestIds.difference(initialSelected);
        final toRemove = initialSelected.difference(selectedTestIds);

        for (final testasId in toRemove) {
          await Api.deleteSablonasTestas(existing.id, testasId);
        }
        for (final testasId in toAdd) {
          await Api.createSablonasTestas({
            'sablonasid': existing.id,
            'testasid': testasId,
          });
        }

        if (!mounted) return;
        setState(() {
          final idx = _items.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) {
            _items[idx] = Sablonas(id: existing.id, pavadinimas: name);
            _items.sort(
              (a, b) => a.pavadinimas.toLowerCase().compareTo(
                b.pavadinimas.toLowerCase(),
              ),
            );
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Šablonas išsaugotas')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(Sablonas it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti šabloną?'),
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
      await Api.deleteSablonas(it.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.id == it.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Šablonas pašalintas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Šablonai',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _createOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Naujas šablonas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _items.isEmpty
                            ? Center(
                                child: Text(
                                  'Nėra šablonų',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 600;

                                  if (isNarrow) {
                                    return ListView.separated(
                                      itemCount: _items.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (ctx, index) {
                                        final it = _items[index];
                                        return Card(
                                          margin: EdgeInsets.zero,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              10,
                                              12,
                                              8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  it.pavadinimas,
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
                                                      onPressed: () =>
                                                          _createOrEdit(
                                                            existing: it,
                                                          ),
                                                      icon: const Icon(Icons.edit),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Ištrinti',
                                                      onPressed: () => _delete(it),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
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
                                          DataColumn(
                                            label: Text('Pavadinimas'),
                                          ),
                                          DataColumn(label: Text('Veiksmai')),
                                        ],
                                        rows: _items.map((it) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(it.pavadinimas)),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Redaguoti',
                                                      onPressed: () =>
                                                          _createOrEdit(
                                                            existing: it,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Ištrinti',
                                                      onPressed: () => _delete(it),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
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
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
