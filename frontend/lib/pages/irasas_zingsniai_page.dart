import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.fetchTestasIrasai(),
        Api.fetchTestai(),
        Api.fetchZingsnisTemplates(),
        Api.fetchZingsniai(),
      ]);

      final allLinks = (results[0] as List<dynamic>)
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .toList();
      final links = allLinks.where((e) => e.irasasId == widget.irasas.id).toList();

      final tests = (results[1] as List<dynamic>)
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
      final testaiById = {for (final t in tests) t.id: t};

      final templates = (results[2] as List<dynamic>)
          .map((e) => ZingsnisTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      final templatesByTest = <int, List<ZingsnisTemplate>>{};
      for (final t in templates) {
        templatesByTest.putIfAbsent(t.testasId, () => []).add(t);
      }
      for (final entry in templatesByTest.entries) {
        entry.value.sort((a, b) => a.eile.compareTo(b.eile));
      }

      final zingsniai = (results[3] as List<dynamic>)
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
    final completedAt = draft.completed ? DateTime.now().toUtc() : null;

    try {
      final userId = await _currentUserIdOrEmpty();
      final existing = _zingsniaiByKey[key];

      if (existing == null) {
        final created = await Api.createZingsnis({
          'komentaras': komentaras.isEmpty ? '-' : komentaras,
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
          'komentaras': komentaras.isEmpty ? '-' : komentaras,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${tpl.eile}. ${tpl.pavadinimas}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tpl.aprasymas,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
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
                                                          () => draft.completed = (v ?? false),
                                                        ),
                                                        controlAffinity:
                                                            ListTileControlAffinity
                                                                .leading,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        title: const Text('Pabaigtas'),
                                                      ),
                                                    ),
                                                    FilledButton.icon(
                                                      onPressed: () => _saveStep(
                                                        link: link,
                                                        template: tpl,
                                                      ),
                                                      icon: const Icon(Icons.save),
                                                      label: const Text('Išsaugoti'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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