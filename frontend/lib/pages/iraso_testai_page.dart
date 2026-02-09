import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class IrasoTestaiPage extends StatefulWidget {
  final Irasas irasas;

  const IrasoTestaiPage({super.key, required this.irasas});

  @override
  State<IrasoTestaiPage> createState() => _IrasoTestaiPageState();
}

class _IrasoTestaiPageState extends State<IrasoTestaiPage> {
  bool _loading = true;
  List<TestasIrasas> _links = [];
  Map<int, Testas> _testaiById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final linksRaw = await Api.fetchTestasIrasai();
      final allLinks = linksRaw
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .toList();

      final attached = allLinks
          .where((e) => e.irasasid == widget.irasas.id)
          .toList();

      final testaiRaw = await Api.fetchTestai();
      final testai = testaiRaw
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _links = attached;
        _testaiById = {for (final t in testai) t.id: t};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida kraunant įrašo testus: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setCompleted(TestasIrasas link, bool value) async {
    final prev = link.atliktas;
    setState(() => link.atliktas = value);

    try {
      await Api.updateTestasIrasas(link.testasid, link.irasasid, {
        'testasid': link.testasid,
        'irasasid': link.irasasid,
        'atliktas': value,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => link.atliktas = prev);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida atnaujinant: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.irasas.pavadinimas;

    return AppScaffold(
      title: 'Testai: $title',
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _links.isEmpty
                        ? Center(
                            child: Text(
                              'Šiam įrašui testų nepridėta',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _links.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final link = _links[idx];
                              final testas = _testaiById[link.testasid];
                              return CheckboxListTile(
                                value: link.atliktas,
                                onChanged: (v) {
                                  if (v == null) return;
                                  _setCompleted(link, v);
                                },
                                title: Text(
                                  testas?.testotekstas ??
                                      'Testas #${link.testasid}',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
