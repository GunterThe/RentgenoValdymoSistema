import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class ZinutesPage extends StatefulWidget {
  const ZinutesPage({super.key});

  @override
  State<ZinutesPage> createState() => _ZinutesPageState();
}

class _InboxItem {
  final int zinuteId;
  final String tekstas;
  final bool perskaityta;

  const _InboxItem({
    required this.zinuteId,
    required this.tekstas,
    required this.perskaityta,
  });

  factory _InboxItem.fromJson(Map<String, dynamic> json) {
    final zinuteId = json['zinuteId'];
    return _InboxItem(
      zinuteId: zinuteId is int ? zinuteId : int.parse(zinuteId.toString()),
      tekstas: (json['tekstas'] ?? '').toString(),
      perskaityta: (json['perskaityta'] as bool?) ?? false,
    );
  }
}

class _ZinutesPageState extends State<ZinutesPage> {
  bool _loading = false;
  bool _busy = false;
  List<_InboxItem> _items = const [];
  String? _error;

  bool get _isAdmin => AuthService.instance.isAdmin;

  Future<void> _load() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await Api.fetchMyInboxZinutes();
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(_InboxItem.fromJson)
          .toList();

      items.sort((a, b) => b.zinuteId.compareTo(a.zinuteId));

      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markRead(_InboxItem item, bool perskaityta) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Api.markInboxZinuteRead(
        zinuteId: item.zinuteId,
        perskaityta: perskaityta,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nepavyko atnaujinti: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(_InboxItem item) async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ištrinti žinutę?'),
          content: const Text('Ši žinutė bus pašalinta iš jūsų sąrašo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ištrinti'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await Api.deleteInboxZinute(zinuteId: item.zinuteId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nepavyko ištrinti: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildList(List<_InboxItem> items, {required bool readTab}) {
    if (_loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Klaida: $_error'));
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          readTab ? 'Perskaitytų žinučių nėra' : 'Naujų žinučių nėra',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = items[idx];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Žinutė #${item.zinuteId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (readTab)
                      IconButton(
                        tooltip: 'Ištrinti',
                        onPressed: _busy ? null : () => _delete(item),
                        icon: const Icon(Icons.delete_outline),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: _busy ? null : () => _markRead(item, true),
                        child: const Text('Pažymėti perskaityta'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.tekstas, style: const TextStyle(height: 1.25)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (_isAdmin) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const AppScaffold(
        title: 'Žinutės',
        body: Center(child: Text('Šis puslapis skirtas tik administratoriams')),
      );
    }

    final unread = _items.where((x) => !x.perskaityta).toList();
    final read = _items.where((x) => x.perskaityta).toList();

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Žinutės',
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Atnaujinti',
            onPressed: (_loading || _busy) ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: SafeArea(
          child: Column(
            children: [
              const Material(
                child: TabBar(
                  tabs: [
                    Tab(text: 'Naujos'),
                    Tab(text: 'Perskaitytos'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(unread, readTab: false),
                    _buildList(read, readTab: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
