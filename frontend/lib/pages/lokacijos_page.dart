import 'package:flutter/material.dart';

import '../models/lokacija.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class LokacijosPage extends StatefulWidget {
  const LokacijosPage({super.key});

  @override
  State<LokacijosPage> createState() => _LokacijosPageState();
}

class _LokacijosPageState extends State<LokacijosPage> {
  List<Lokacija> _items = [];
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
      final list = await Api.fetchLokacijos();
      final items = list
          .map((e) => Lokacija.fromJson(e as Map<String, dynamic>))
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
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant lokacijas: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({Lokacija? existing}) async {
    final ctrl = TextEditingController(text: existing?.pavadinimas ?? '');

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nauja lokacija' : 'Redaguoti lokaciją'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Pavadinimas'),
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
    );

    if (ok != true) return;

    final name = ctrl.text.trim();
    try {
      if (existing == null) {
        final created = await Api.createLokacija({'pavadinimas': name});
        final it = Lokacija.fromJson(created);
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
        ).showSnackBar(const SnackBar(content: Text('Lokacija sukurta')));
      } else {
        await Api.updateLokacija(existing.id, {
          'id': existing.id,
          'pavadinimas': name,
        });
        if (!mounted) return;
        setState(() {
          final idx = _items.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) {
            _items[idx] = Lokacija(id: existing.id, pavadinimas: name);
            _items.sort(
              (a, b) => a.pavadinimas.toLowerCase().compareTo(
                b.pavadinimas.toLowerCase(),
              ),
            );
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lokacija išsaugota')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _delete(Lokacija it) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti lokaciją?'),
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
      await Api.deleteLokacija(it.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.id == it.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lokacija pašalinta')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredItems = query.isEmpty
        ? _items
        : _items
              .where((e) => e.pavadinimas.toLowerCase().contains(query))
              .toList();

    return AppScaffold(
      title: 'Lokacijos',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _createOrEdit(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nauja lokacija'),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'Ieškoti lokacijos…',
                                suffixIcon: _query.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Išvalyti',
                                        onPressed: () =>
                                            setState(() => _query = ''),
                                        icon: const Icon(Icons.clear),
                                      ),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _items.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nėra lokacijų',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : filteredItems.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nieko nerasta',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isNarrow =
                                            constraints.maxWidth < 600;

                                        if (isNarrow) {
                                          return ListView.separated(
                                            itemCount: filteredItems.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (ctx, index) {
                                              final it = filteredItems[index];
                                              return Card(
                                                margin: EdgeInsets.zero,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        10,
                                                        12,
                                                        8,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Text(
                                                        it.pavadinimas,
                                                        style:
                                                            const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  0.1,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        alignment:
                                                            WrapAlignment.end,
                                                        children: [
                                                          IconButton(
                                                            tooltip:
                                                                'Redaguoti',
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
                                                            onPressed: () =>
                                                                _delete(it),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
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
                                                DataColumn(
                                                  label: Text('Veiksmai'),
                                                ),
                                              ],
                                              rows: filteredItems.map((it) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(it.pavadinimas),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            tooltip:
                                                                'Redaguoti',
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
                                                            onPressed: () =>
                                                                _delete(it),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
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
                          ],
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
