import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/irasas.dart';
import '../models/lokacija.dart';
import '../models/sablonas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
import '../models/zingsnis.dart';
import '../models/zingsnis_template.dart';
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
  final Set<String> _statusFilters = <String>{};
  int? _lokacijaFilterId;
  final Map<int, String> _lokacijaNameById = {};
  Map<int, String> _komentaraiByIrasasId = {};
  bool _komentaraiLoaded = false;
  bool _komentaraiLoading = false;

  String _normalizeKomentaras(String? s) {
    final t = (s ?? '').trim();
    if (t == '-') return '';
    return t;
  }

  Future<void> _ensureKomentaraiIndexLoaded() async {
    if (_komentaraiLoaded || _komentaraiLoading) return;

    if (mounted) {
      setState(() => _komentaraiLoading = true);
    }

    try {
      final results = await Future.wait([
        Api.fetchTestasIrasai(),
        Api.fetchZingsniai(),
      ]);

      final links = (results[0])
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .toList();

      final irasasIdByLinkId = <int, int>{
        for (final l in links) l.id: l.irasasId,
      };

      final zingsniai = (results[1])
          .map((e) => Zingsnis.fromJson(e as Map<String, dynamic>))
          .toList();

      final buffers = <int, StringBuffer>{};
      for (final z in zingsniai) {
        final irId = irasasIdByLinkId[z.testasIrasasId];
        if (irId == null) continue;
        final comment = _normalizeKomentaras(z.komentaras);
        if (comment.isEmpty) continue;

        final b = buffers.putIfAbsent(irId, StringBuffer.new);
        if (b.isNotEmpty) b.write(' ');
        b.write(comment.toLowerCase());
      }

      final map = <int, String>{
        for (final e in buffers.entries) e.key: e.value.toString(),
      };

      if (!mounted) return;
      setState(() {
        _komentaraiByIrasasId = map;
        _komentaraiLoaded = true;
        _komentaraiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _komentaraiLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant komentarus: $e')));
    }
  }

  String _statusCategory(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return 'kita';
    if (s.startsWith('neprad')) return 'nepradetas';
    if (s.startsWith('pabaig')) return 'pabaigtas';
    if (s.startsWith('ant ')) return 'ant';
    return 'kita';
  }

  String _prettyStatus(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final cat = _statusCategory(t);
    if (cat == 'nepradetas') return 'Nepradėtas';
    if (cat == 'pabaigtas') return 'Pabaigtas';
    if (cat == 'ant') {
      return 'Ant${t.length > 3 ? t.substring(3) : ''}';
    }
    return t;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.fetchIrasai(),
        Api.fetchLokacijos(),
      ]);

      final list = results[0];
      final locList = results[1];

      final items = list
          .map((e) => Irasas.fromJson(e as Map<String, dynamic>))
          .toList();

      final locs = locList
          .map((e) => Lokacija.fromJson(e as Map<String, dynamic>))
          .toList();

      final locMap = <int, String>{for (final l in locs) l.id: l.pavadinimas};

      if (!mounted) return;
      setState(() {
        _items = items;
        _lokacijaNameById
          ..clear()
          ..addAll(locMap);

        if (_lokacijaFilterId != null &&
            !_lokacijaNameById.containsKey(_lokacijaFilterId)) {
          _lokacijaFilterId = null;
        }

        _komentaraiByIrasasId = {};
        _komentaraiLoaded = false;
        _komentaraiLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant įrašus: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _lokacijaName(int lokacijaId) {
    final name = (_lokacijaNameById[lokacijaId] ?? '').trim();
    if (name.isNotEmpty) return name;
    return lokacijaId > 0 ? 'Lokacija #$lokacijaId' : '-';
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '---';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$y-$m-$d';
  }

  int _compareNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  List<Irasas> _filteredAndSortedItems() {
    final q = _query.trim().toLowerCase();
    bool matchesQuery(Irasas e) {
      if (q.isEmpty) return true;
      if (e.pavadinimas.toLowerCase().contains(q)) return true;
      if (e.idDokumento.toLowerCase().contains(q)) return true;
      final k = _komentaraiByIrasasId[e.id];
      if (k != null && k.contains(q)) return true;
      return false;
    }

    final list = _items.where(matchesQuery).toList();

    final filters = _statusFilters;
    final filtered = filters.isEmpty
        ? list
        : list.where((e) {
            final cat = _statusCategory(e.statusas);
            return filters.contains(cat);
          }).toList();

    final lokId = _lokacijaFilterId;
    final filteredByLokacija = lokId == null
      ? filtered
      : filtered.where((e) => e.lokacijaId == lokId).toList();

    final col = _sortColumnIndex;
    if (col == null) return filteredByLokacija;

    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    filteredByLokacija.sort((a, b) {
      int r;
      switch (col) {
        case 0:
          r = cmp(a.pavadinimas, b.pavadinimas);
          break;
        case 1:
          r = cmp(a.idDokumento, b.idDokumento);
          break;
        case 2:
          r = cmp(_lokacijaName(a.lokacijaId), _lokacijaName(b.lokacijaId));
          break;
        case 3:
          r = cmp(a.statusas, b.statusas);
          break;
        case 4:
          r = a.pradzia.compareTo(b.pradzia);
          break;
        case 5:
          r = _compareNullableDate(a.pabaiga, b.pabaiga);
          break;
        default:
          r = 0;
      }
      return _sortAscending ? r : -r;
    });
    return filteredByLokacija;
  }

  Future<void> _editIrasas(Irasas it) async {
    final idDocCtrl = TextEditingController(text: it.idDokumento);
    final pavCtrl = TextEditingController(text: it.pavadinimas);
    var pradzia = it.pradzia;
    DateTime? pabaiga = it.pabaiga;

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
                          pradzia = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
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
                          initialDate: pabaiga ?? pradzia,
                          firstDate: pradzia,
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pabaiga = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
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
      'pabaiga': pabaiga?.toUtc().toIso8601String(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Įrašas išsaugotas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _createIrasas() async {
    final idDocCtrl = TextEditingController();
    final pavCtrl = TextEditingController();
    var pradzia = DateTime.now();
    DateTime? pabaiga;

    List<Lokacija> lokacijos = const <Lokacija>[];
    List<Sablonas> sablonai = const <Sablonas>[];
    try {
      final results = await Future.wait([
        Api.fetchLokacijos(),
        Api.fetchSablonai(),
      ]);
      final list = results[0];
      final sablList = results[1];

      lokacijos = list
          .map((e) => Lokacija.fromJson(e as Map<String, dynamic>))
          .toList();
      lokacijos.sort(
        (a, b) =>
            a.pavadinimas.toLowerCase().compareTo(b.pavadinimas.toLowerCase()),
      );

      sablonai = sablList
          .map((e) => Sablonas.fromJson(e as Map<String, dynamic>))
          .toList();
      sablonai.sort(
        (a, b) =>
            a.pavadinimas.toLowerCase().compareTo(b.pavadinimas.toLowerCase()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant lokacijas: $e')));
      return;
    }

    if (lokacijos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nėra lokacijų. Pirma sukurkite lokaciją.'),
        ),
      );
      return;
    }

    int? lokacijaId = lokacijos.first.id;
    int? sablonasId;

    // Žingsnių vartai: per testą pasirenkami privalomi žingsniai (templates),
    // kurie turi būti atlikti prieš leidžiant užbaigti kitus žingsnius.
    final vartaiByTestasId = <int, Set<int>>{};

    int vartaiCount() => vartaiByTestasId.values.fold<int>(
      0,
      (sum, set) => sum + set.length,
    );

    Future<void> pickVartaiForSablonas() async {
      if (sablonasId == null) return;

      try {
        final results = await Future.wait([
          Api.fetchSablonasTestai(),
          Api.fetchZingsnisTemplates(),
          Api.fetchTestai(),
        ]);

        final links = (results[0]).cast<dynamic>();
        final templates = (results[1])
            .map((e) => ZingsnisTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
        final testai = (results[2])
            .map((e) => Testas.fromJson(e as Map<String, dynamic>))
            .toList();
        final testById = {for (final t in testai) t.id: t};

        final sablonasTestai = <({int testasId, int eile})>[];
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
          final e = (raw['eile'] ?? raw['Eile']);

          if (sid is int && tid is int && sid == sablonasId) {
            sablonasTestai.add(
              (testasId: tid, eile: (e is int && e > 0) ? e : 1 << 30),
            );
          }
        }
        sablonasTestai.sort((a, b) {
          final c = a.eile.compareTo(b.eile);
          if (c != 0) return c;
          return a.testasId.compareTo(b.testasId);
        });

        final templatesByTest = <int, List<ZingsnisTemplate>>{};
        for (final t in templates) {
          templatesByTest.putIfAbsent(t.testasId, () => []).add(t);
        }
        for (final entry in templatesByTest.entries) {
          entry.value.sort((a, b) => a.eile.compareTo(b.eile));
        }

        await showDialog<void>(
          context: context,
          builder: (dialogCtx) => StatefulBuilder(
            builder: (dialogCtx, setLocalDialog) => AlertDialog(
              title: const Text('Žingsnių vartai'),
              content: SizedBox(
                width: 560,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sablonasTestai.length,
                    itemBuilder: (dialogCtx, index) {
                      final testasId = sablonasTestai[index].testasId;
                      final testName =
                          testById[testasId]?.testotekstas ?? 'Testas #$testasId';
                      final tpls =
                          templatesByTest[testasId] ??
                          const <ZingsnisTemplate>[];

                      vartaiByTestasId.putIfAbsent(testasId, () => <int>{});
                      final selected = vartaiByTestasId[testasId]!;

                      return ExpansionTile(
                        title: Text(testName),
                        subtitle: Text(
                          selected.isEmpty
                              ? 'Vartų nėra (visi žingsniai laisvi)'
                              : 'Vartai: ${selected.length}',
                        ),
                        children: [
                          if (tpls.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Text(
                                'Šis testas neturi žingsnių šablonų',
                                style: TextStyle(
                                  color: Theme.of(dialogCtx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ...tpls.map((tpl) {
                              final checked = selected.contains(tpl.id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text('${tpl.eile}. ${tpl.pavadinimas}'),
                                subtitle: Text(tpl.aprasymas),
                                onChanged: (v) {
                                  setLocalDialog(() {
                                    final next = v ?? false;
                                    if (next) {
                                      selected.add(tpl.id);
                                    } else {
                                      selected.remove(tpl.id);
                                    }
                                  });
                                },
                              );
                            }),
                        ],
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Uždaryti'),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Klaida kraunant vartus: $e')),
        );
      }
    }

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
              DropdownButtonFormField<int>(
                initialValue: lokacijaId,
                decoration: const InputDecoration(labelText: 'Lokacija'),
                items: lokacijos
                    .map(
                      (l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.pavadinimas),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => lokacijaId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: sablonasId,
                decoration: const InputDecoration(
                  labelText: 'Šablonas (nebūtina)',
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('-')),
                  ...sablonai.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(s.pavadinimas),
                    ),
                  ),
                ],
                onChanged: (v) => setLocal(() {
                  sablonasId = v;
                  vartaiByTestasId.clear();
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed:
                      sablonasId == null ? null : () => pickVartaiForSablonas(),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(
                    vartaiCount() == 0
                        ? 'Žingsnių vartai'
                        : 'Žingsnių vartai (${vartaiCount()})',
                  ),
                ),
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
                          pradzia = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
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
                          initialDate: pabaiga ?? pradzia,
                          firstDate: pradzia,
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setLocal(() {
                          pabaiga = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
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
      'pabaiga': pabaiga?.toUtc().toIso8601String(),
      'lokacijaId': lokacijaId,
      'sablonasId': sablonasId,
      'zingsniuVartai': vartaiByTestasId.entries
          .where((e) => e.value.isNotEmpty)
          .map(
            (e) => {
              'testasId': e.key,
              'zingsnisTemplateIds': (e.value.toList()..sort()),
            },
          )
          .toList(),
    };

    if ((payload['pavadinimas'] as String).isEmpty ||
        (payload['idDokumento'] as String).isEmpty ||
        (payload['lokacijaId'] as int?) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Užpildykite pavadinimą, dokumento ID ir pasirinkite lokaciją',
          ),
        ),
      );
      return;
    }

    try {
      final created = await Api.createIrasas(payload);
      final it = Irasas.fromJson(created);
      if (!mounted) return;
      setState(() => _items.add(it));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Įrašas sukurtas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Testas pridėtas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
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
      final linkedTests = testai
          .where((t) => linkedTestIds.contains(t.id))
          .toList();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Testas pašalintas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              labelText:
                                  'Paieška pagal pavadinimą / dokumento ID / komentarą',
                            ),
                            onChanged: (v) {
                              setState(() => _query = v);
                              if (v.trim().isNotEmpty) {
                                _ensureKomentaraiIndexLoaded();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              FilterChip(
                                label: const Text('Nepradėtas'),
                                selected: _statusFilters.contains('nepradetas'),
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _statusFilters.add('nepradetas');
                                  } else {
                                    _statusFilters.remove('nepradetas');
                                  }
                                }),
                              ),
                              FilterChip(
                                label: const Text('Ant'),
                                selected: _statusFilters.contains('ant'),
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _statusFilters.add('ant');
                                  } else {
                                    _statusFilters.remove('ant');
                                  }
                                }),
                              ),
                              FilterChip(
                                label: const Text('Pabaigtas'),
                                selected: _statusFilters.contains('pabaigtas'),
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _statusFilters.add('pabaigtas');
                                  } else {
                                    _statusFilters.remove('pabaigtas');
                                  }
                                }),
                              ),
                              if (_statusFilters.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _statusFilters.clear();
                                  }),
                                  child: const Text('Valyti'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      key: ValueKey(_lokacijaFilterId),
                      initialValue: _lokacijaFilterId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lokacija',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Visos'),
                        ),
                        ...(_lokacijaNameById.entries.toList()
                              ..sort(
                                (a, b) => a.value
                                    .toLowerCase()
                                    .compareTo(b.value.toLowerCase()),
                              ))
                            .map(
                              (e) => DropdownMenuItem<int?>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            ),
                      ],
                      onChanged: (v) => setState(() => _lokacijaFilterId = v),
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
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 800;
                                    final cs = Theme.of(context).colorScheme;

                                    if (isNarrow) {
                                      return ListView.separated(
                                        itemCount: shown.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (ctx, index) {
                                          final it = shown[index];
                                          final status = _prettyStatus(it.statusas);
                                          final lok = _lokacijaName(it.lokacijaId);
                                          final pr = _fmtDate(it.pradzia);
                                          final pb = _fmtDate(it.pabaiga);

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
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    it.pavadinimas,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Dokumento ID: ${it.idDokumento}',
                                                    style: TextStyle(
                                                      color: cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Lokacija: $lok',
                                                    style: TextStyle(
                                                      color: cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Statusas: $status',
                                                    style: TextStyle(
                                                      color: cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Laikas: $pr – $pb',
                                                    style: TextStyle(
                                                      color: cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    alignment: WrapAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Peržiūrėti',
                                                        onPressed: () =>
                                                            Navigator.of(context)
                                                                .push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                IrasasZingsniaiPage(
                                                              irasas: it,
                                                            ),
                                                          ),
                                                        ),
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_red_eye_outlined,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Redaguoti',
                                                        onPressed: () =>
                                                            _editIrasas(it),
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Pridėti testą',
                                                        onPressed: () =>
                                                            _addTestToIrasas(it),
                                                        icon: const Icon(
                                                          Icons.playlist_add,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Pašalinti testą',
                                                        onPressed: () =>
                                                            _removeTestFromIrasas(
                                                              it,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .playlist_remove,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Ištrinti',
                                                        onPressed: () =>
                                                            _deleteIrasas(it),
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
                                              label: const Text('Lokacija'),
                                              onSort: (i, asc) => setState(() {
                                                _sortColumnIndex = i;
                                                _sortAscending = asc;
                                              }),
                                            ),
                                            DataColumn(
                                              label: const Text('Statusas'),
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
                                                  Text(_lokacijaName(it.lokacijaId)),
                                                ),
                                                DataCell(
                                                  Text(_prettyStatus(it.statusas)),
                                                ),
                                                DataCell(Text(_fmtDate(it.pradzia))),
                                                DataCell(Text(_fmtDate(it.pabaiga))),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Peržiūrėti',
                                                        onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) =>
                                                                      IrasasZingsniaiPage(
                                                                    irasas: it,
                                                                  ),
                                                                ),
                                                              ),
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_red_eye_outlined,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Redaguoti',
                                                        onPressed: () =>
                                                            _editIrasas(it),
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Pridėti testą',
                                                        onPressed: () =>
                                                            _addTestToIrasas(it),
                                                        icon: const Icon(
                                                          Icons.playlist_add,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Pašalinti testą',
                                                        onPressed: () =>
                                                            _removeTestFromIrasas(
                                                              it,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .playlist_remove,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Ištrinti',
                                                        onPressed: () =>
                                                            _deleteIrasas(it),
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
                  ],
                ),
              ),
            ),
    );
  }
}
