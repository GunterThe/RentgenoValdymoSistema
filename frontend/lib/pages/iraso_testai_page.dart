import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/irasas.dart';
import '../models/prisegtas_failas.dart';
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

  bool _loadingFailai = true;
  List<PrisegtasFailas> _failai = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadingFailai = true;
    });
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

      final failaiRaw = await Api.fetchPrisegtiFailaiByIrasas(widget.irasas.id);
      final failai = failaiRaw
          .map((e) => PrisegtasFailas.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _links = attached;
        _testaiById = {for (final t in testai) t.id: t};
        _failai = failai;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida kraunant įrašo testus: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingFailai = false;
        });
      }
    }
  }

  bool _isImageFileName(String name) {
    final dot = name.lastIndexOf('.');
    final ext = (dot >= 0 ? name.substring(dot + 1) : name).toLowerCase();
    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'gif' ||
        ext == 'webp' ||
        ext == 'bmp';
  }

  String _fmtSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _downloadFailas(PrisegtasFailas f) async {
    final uri = Api.prisegtasFailasDownloadUri(f.id);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko atidaryti atsisiuntimo nuorodos')),
      );
    }
  }

  Future<void> _openFailasPreview(PrisegtasFailas f) async {
    final isImg = _isImageFileName(f.fileName);
    if (!isImg) {
      await _downloadFailas(f);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final uri = Api.prisegtasFailasFileUri(f.id);
        return AlertDialog(
          title: Text(f.fileName),
          content: SizedBox(
            width: 640,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  uri.toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) {
                    return Center(
                      child: Text(
                        'Nepavyko įkelti paveikslėlio',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Uždaryti'),
            ),
            FilledButton.icon(
              onPressed: () => _downloadFailas(f),
              icon: const Icon(Icons.download),
              label: const Text('Atsisiųsti'),
            ),
          ],
        );
      },
    );
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _links.isEmpty
                          ? Center(
                              child: Text(
                                'Šiam įrašui testų nepridėta',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _loadingFailai
                          ? const Center(child: CircularProgressIndicator())
                          : _failai.isEmpty
                              ? Center(
                                  child: Text(
                                    'Failų nepridėta',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Failai',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._failai.map((f) {
                                      final isImg = _isImageFileName(f.fileName);
                                      final size = _fmtSize(f.size);
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: isImg
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  Api.prisegtasFailasFileUri(f.id)
                                                      .toString(),
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error, stack) {
                                                    return const SizedBox(
                                                      width: 44,
                                                      height: 44,
                                                      child: Icon(
                                                        Icons.image_not_supported_outlined,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : const SizedBox(
                                                width: 44,
                                                height: 44,
                                                child: Icon(
                                                  Icons.insert_drive_file_outlined,
                                                ),
                                              ),
                                        title: Text(f.fileName),
                                        subtitle: size.isEmpty ? null : Text(size),
                                        trailing: IconButton(
                                          tooltip: 'Atsisiųsti',
                                          onPressed: () => _downloadFailas(f),
                                          icon: const Icon(Icons.download),
                                        ),
                                        onTap: () => _openFailasPreview(f),
                                      );
                                    }),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
