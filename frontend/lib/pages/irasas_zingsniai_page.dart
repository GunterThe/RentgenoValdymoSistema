import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/irasas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
import '../models/naudotojas.dart';
import '../models/prisegtas_failas.dart';
import '../models/zingsnis.dart';
import '../models/zingsnis_template.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/jwt_utils.dart';
import '../widgets/app_scaffold.dart';

class IrasasZingsniaiPage extends StatefulWidget {
  final Irasas irasas;

  const IrasasZingsniaiPage({super.key, required this.irasas});

  @override
  State<IrasasZingsniaiPage> createState() => _IrasasZingsniaiPageState();
}

class _StepDraft {
  final TextEditingController komentarasCtrl;
  bool completed;

  _StepDraft({required String komentaras, required this.completed})
      : komentarasCtrl = TextEditingController(text: komentaras);
}

class _IrasasZingsniaiPageState extends State<IrasasZingsniaiPage> {
  bool _loading = true;

  List<TestasIrasas> _links = [];
  Map<int, Testas> _testaiById = {};
  Map<int, List<ZingsnisTemplate>> _templatesByTestasId = {};
  Map<String, Zingsnis> _zingsniaiByKey = {};

  final Map<int, List<PrisegtasFailas>> _failaiByZingsnisId = {};
  final Set<int> _loadingFailaiForZingsnis = {};

  final Map<String, Naudotojas> _naudotojaiById = {};
  final Set<String> _loadingNaudotojai = {};

  final Map<String, _StepDraft> _drafts = {};

  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _k(int testasIrasasId, int templateId) => '$testasIrasasId:$templateId';

  Future<String> _currentUserIdOrEmpty() async {
    final access = await AuthService.instance.getValidAccessToken();
    if (access == null || access.isEmpty) return _emptyGuid;
    return JwtUtils.tryGetSubject(access) ?? _emptyGuid;
  }

  Future<void> _ensureNaudotojasLoaded(String id) async {
    final userId = id.trim();
    if (userId.isEmpty) return;
    if (_naudotojaiById.containsKey(userId)) return;
    if (_loadingNaudotojai.contains(userId)) return;

    setState(() => _loadingNaudotojai.add(userId));
    try {
      final j = await Api.fetchNaudotojas(userId);
      final n = Naudotojas.fromJson(j);
      if (!mounted) return;
      setState(() => _naudotojaiById[userId] = n);
    } catch (_) {
      // Ignore lookup failures; we'll fall back to "-".
    } finally {
      if (!mounted) return;
      setState(() => _loadingNaudotojai.remove(userId));
    }
  }

  String _displayNameOrFallback(String id) {
    final userId = id.trim();
    if (userId.isEmpty) return '-';
    final n = _naudotojaiById[userId];
    final name = n?.fullName.trim() ?? '';
    return name.isEmpty ? '-' : name;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.fetchTestasIrasai(),
        Api.fetchTestai(),
        Api.fetchZingsnisTemplates(),
        Api.fetchZingsniai(),
      ]);

      final allLinks = (results[0])
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .toList();
      final links = allLinks.where((e) => e.irasasId == widget.irasas.id).toList();

      final tests = (results[1])
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
      final testaiById = {for (final t in tests) t.id: t};

      final templates = (results[2])
          .map((e) => ZingsnisTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      final templatesByTest = <int, List<ZingsnisTemplate>>{};
      for (final t in templates) {
        templatesByTest.putIfAbsent(t.testasId, () => []).add(t);
      }
      for (final entry in templatesByTest.entries) {
        entry.value.sort((a, b) => a.eile.compareTo(b.eile));
      }

      final zingsniai = (results[3])
          .map((e) => Zingsnis.fromJson(e as Map<String, dynamic>))
          .toList();
      final zingsniaiByKey = <String, Zingsnis>{};
      for (final z in zingsniai) {
        zingsniaiByKey[_k(z.testasIrasasId, z.zingsnisTemplateId)] = z;
      }

      if (!mounted) return;
      setState(() {
        _links = links;
        _testaiById = testaiById;
        _templatesByTestasId = templatesByTest;
        _zingsniaiByKey = zingsniaiByKey;

        _drafts.clear();
        for (final link in links) {
          final templ = templatesByTest[link.testasId] ?? const <ZingsnisTemplate>[];
          for (final tpl in templ) {
            final key = _k(link.id, tpl.id);
            final existing = zingsniaiByKey[key];
            _drafts[key] = _StepDraft(
              komentaras: existing?.komentaras ?? '',
              completed: existing?.completedAt != null,
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida kraunant žingsnius: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStep({
    required TestasIrasas link,
    required ZingsnisTemplate template,
  }) async {
    final key = _k(link.id, template.id);
    final draft = _drafts[key];
    if (draft == null) return;

    final komentaras = draft.komentarasCtrl.text.trim();
    var completedAt = draft.completed ? DateTime.now().toUtc() : null;

    String normKomentaras(String s) {
      final t = s.trim();
      return (t == '-' ? '' : t);
    }

    final existing = _zingsniaiByKey[key];
    final existingKomentaras = normKomentaras(existing?.komentaras ?? '');
    final draftKomentaras = normKomentaras(komentaras);
    final existingCompleted = existing?.completedAt != null;
    final draftCompleted = draft.completed;

    final isNoOp = existing != null &&
        existingKomentaras == draftKomentaras &&
        existingCompleted == draftCompleted;

    final isBlankNew = existing == null &&
        draftKomentaras.isEmpty &&
        draftCompleted == false;

    if (isBlankNew) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nieko neužpildyta: parašyk komentarą arba pažymėk pabaigtą'),
        ),
      );
      return;
    }

    if (isNoOp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nieko nepakeista')),
      );
      return;
    }

    try {
      final userId = await _currentUserIdOrEmpty();
      if (draft.completed == false) { completedAt = null; }

      if (existing == null) {
        final created = await Api.createZingsnis({
          'komentaras': draftKomentaras.isEmpty ? '-' : draftKomentaras,
          'completedAt': completedAt?.toIso8601String(),
          'testasIrasasId': link.id,
          'zingsnisTemplateId': template.id,
          'completedByUserId': userId,
        });
        final z = Zingsnis.fromJson(created);
        if (!mounted) return;
        setState(() {
          _zingsniaiByKey[key] = z;
        });
      } else {
        final payload = {
          'id': existing.id,
          'komentaras': draftKomentaras.isEmpty ? '-' : draftKomentaras,
          'completedAt': completedAt?.toIso8601String(),
          'testasIrasasId': link.id,
          'zingsnisTemplateId': template.id,
          'completedByUserId': userId,
        };
        await Api.updateZingsnis(existing.id, payload);
        if (!mounted) return;
        setState(() {
          existing.komentaras = payload['komentaras'] as String;
          existing.completedAt = completedAt?.toLocal();
          existing.completedByUserId = userId;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Žingsnis išsaugotas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida saugant žingsnį: $e')),
      );
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

  String _fmtDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _loadFailai(int zingsnisId) async {
    if (_loadingFailaiForZingsnis.contains(zingsnisId)) return;
    setState(() => _loadingFailaiForZingsnis.add(zingsnisId));
    try {
      final list = await Api.fetchPrisegtiFailaiByZingsnis(zingsnisId);
      final items = list
          .map((e) => PrisegtasFailas.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _failaiByZingsnisId[zingsnisId] = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida kraunant failus: $e')));
    } finally {
      if (mounted) {
        setState(() => _loadingFailaiForZingsnis.remove(zingsnisId));
      }
    }
  }

  Future<void> _attachFile(int zingsnisId) async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: true);
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;

      final fileName = f.name;
      final bytes = f.bytes;
      final path = f.path;

      final created = await Api.uploadPrisegtasFailasToZingsnis(
        zingsnisId: zingsnisId,
        fileName: fileName,
        bytes: bytes,
        filePath: bytes == null ? path : null,
      );

      final pf = PrisegtasFailas.fromJson(created);
      if (!mounted) return;
      setState(() {
        final list = _failaiByZingsnisId[zingsnisId] ?? <PrisegtasFailas>[];
        _failaiByZingsnisId[zingsnisId] = [pf, ...list];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failas pridėtas')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida įkeliant failą: $e')));
    }
  }

  Future<void> _deleteFailas(int zingsnisId, PrisegtasFailas f) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pašalinti failą?'),
        content: Text('Ar tikrai ištrinti "${f.failoPav ?? f.id}"?'),
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
      await Api.deletePrisegtasFailas(f.id);
      if (!mounted) return;
      setState(() {
        final list = _failaiByZingsnisId[zingsnisId] ?? <PrisegtasFailas>[];
        _failaiByZingsnisId[zingsnisId] =
            list.where((e) => e.id != f.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Klaida trynimo metu: $e')));
    }
  }

  Future<void> _openDownload(PrisegtasFailas f) async {
    final uri = Api.prisegtasFailasDownloadUri(f.id);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    for (final d in _drafts.values) {
      d.komentarasCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Žingsniai: ${widget.irasas.pavadinimas}',
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
                child: _links.isEmpty
                    ? Center(
                        child: Text(
                          'Šitam įrašui dar nepridėta testų',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _links.length,
                      separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final link = _links[i];
                          final testas = _testaiById[link.testasId];
                          final templates = _templatesByTestasId[link.testasId] ??
                              const <ZingsnisTemplate>[];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testas?.testotekstas ?? 'Testas #${link.testasId}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (templates.isEmpty)
                                    Text(
                                      'Šitam testui nėra žingsnių template',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    ...templates.map((tpl) {
                                      final key = _k(link.id, tpl.id);
                                      final draft = _drafts[key]!;
                                      final existing = _zingsniaiByKey[key];
                                      final zingsnisId = existing?.id;

                                      final savedCompleted =
                                          existing?.completedAt != null;
                                      final savedCompletedBy =
                                          (existing?.completedByUserId ?? '').trim();
                                      final savedCompletedAt = existing?.completedAt;

                                      final doneIcon = draft.completed
                                          ? Icons.check_circle_outline
                                          : Icons.radio_button_unchecked;

                                      String subtitleText() {
                                        if (zingsnisId == null) {
                                          return draft.completed
                                              ? 'Pabaigtas (neišsaugota)'
                                              : 'Neišsaugota';
                                        }

                                        if (draft.completed) {
                                          if (savedCompleted &&
                                              savedCompletedAt != null) {
                                            final who = _displayNameOrFallback(savedCompletedBy);
                                            return 'Pabaigtas: $who • ${_fmtDateTime(savedCompletedAt)}';
                                          }
                                          return 'Pabaigtas (neišsaugota)';
                                        }

                                        if (!draft.completed && savedCompleted) {
                                          return 'Nepabaigtas (neišsaugota)';
                                        }
                                        return 'Nepabaigtas';
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Card(
                                          child: ExpansionTile(
                                            leading: Icon(
                                              doneIcon,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            title: Text(
                                              '${tpl.eile}. ${tpl.pavadinimas}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            subtitle: Text(
                                              subtitleText(),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            onExpansionChanged: (expanded) {
                                              if (!expanded) return;
                                              if (zingsnisId == null) return;
                                              _loadFailai(zingsnisId);

                                              final who = savedCompletedBy;
                                              if (who.isNotEmpty) {
                                                _ensureNaudotojasLoaded(who);
                                              }
                                            },
                                            childrenPadding:
                                                const EdgeInsets.fromLTRB(
                                              12,
                                              0,
                                              12,
                                              12,
                                            ),
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  tpl.aprasymas,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              if (savedCompleted &&
                                                  savedCompletedAt != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    'Užbaigė: ${_displayNameOrFallback(savedCompletedBy)} • ${_fmtDateTime(savedCompletedAt)}',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: draft.komentarasCtrl,
                                                decoration: const InputDecoration(
                                                  labelText: 'Komentaras',
                                                ),
                                                minLines: 1,
                                                maxLines: 3,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CheckboxListTile(
                                                      value: draft.completed,
                                                      onChanged: (v) => setState(
                                                        () => draft.completed =
                                                            (v ?? false),
                                                      ),
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      title:
                                                          const Text('Pabaigtas'),
                                                    ),
                                                  ),
                                                  FilledButton.icon(
                                                    onPressed: () => _saveStep(
                                                      link: link,
                                                      template: tpl,
                                                    ),
                                                    icon: const Icon(Icons.save),
                                                    label:
                                                        const Text('Išsaugoti'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Failai',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  FilledButton.icon(
                                                    onPressed: zingsnisId == null
                                                        ? () {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Pirma išsaugokite žingsnį',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        : () => _attachFile(
                                                              zingsnisId,
                                                            ),
                                                    icon:
                                                        const Icon(Icons.attach_file),
                                                    label: const Text('Pridėti'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (zingsnisId != null &&
                                                  _loadingFailaiForZingsnis
                                                      .contains(zingsnisId))
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 6),
                                                  child: LinearProgressIndicator(),
                                                ),
                                              if (zingsnisId != null)
                                                ...(_failaiByZingsnisId[zingsnisId] ??
                                                        const <PrisegtasFailas>[])
                                                    .map(
                                                      (f) => ListTile(
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        title: Text(
                                                          f.failoPav ?? f.id,
                                                        ),
                                                        subtitle: Text(
                                                          _fmtBytes(f.dydis),
                                                        ),
                                                        trailing: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              tooltip: 'Atsisiųsti',
                                                              onPressed: () =>
                                                                  _openDownload(f),
                                                              icon: const Icon(
                                                                Icons
                                                                    .download_outlined,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              tooltip: 'Pašalinti',
                                                              onPressed: () =>
                                                                  _deleteFailas(
                                                                zingsnisId,
                                                                f,
                                                              ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
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