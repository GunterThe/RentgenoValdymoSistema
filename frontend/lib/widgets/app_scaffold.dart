import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/auth_service.dart';

void showPlaceholder(BuildContext context, String title) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$title - dar neįgyvendinta')));
}

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  List<Widget> _defaultActions(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    return [
      IconButton(
        tooltip: 'Paskyra',
        onPressed: () => Navigator.of(context).pushNamed('/paskyra'),
        icon: const Icon(Icons.person_outline),
      ),
      if (isAdmin) const _AdminInboxIconButton(),
      IconButton(
        tooltip: 'Atsijungti',
        onPressed: () async {
          await AuthService.instance.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        },
        icon: const Icon(Icons.logout),
      ),
      IconButton(
        tooltip: 'Testai',
        onPressed: () => Navigator.of(context).pushNamed('/testai'),
        icon: const Icon(Icons.list_alt),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [..._defaultActions(context), ...actions],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

class _AdminInboxIconButton extends StatefulWidget {
  const _AdminInboxIconButton();

  @override
  State<_AdminInboxIconButton> createState() => _AdminInboxIconButtonState();
}

class _AdminInboxIconButtonState extends State<_AdminInboxIconButton> {
  bool _hasUnread = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final list = await Api.fetchMyInboxZinutes();
      final hasUnread = list.whereType<Map<String, dynamic>>().any(
        (x) => (x['perskaityta'] as bool?) == false,
      );
      if (!mounted) return;
      setState(() => _hasUnread = hasUnread);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasUnread = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInbox() async {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == '/zinutes') {
      await _refresh();
      return;
    }

    await Navigator.of(context).pushNamed('/zinutes');
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = const Icon(Icons.markunread_outlined);

    if (_hasUnread) {
      icon = Badge(label: const Text('!'), child: icon);
    }

    return IconButton(tooltip: 'Žinutės', onPressed: _openInbox, icon: icon);
  }
}
