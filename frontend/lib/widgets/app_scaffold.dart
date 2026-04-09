import 'package:flutter/material.dart';

import '../services/auth_service.dart';

void showPlaceholder(BuildContext context, String title) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$title - dar neįgyvendinta')),
  );
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
      if (isAdmin)
        IconButton(
          tooltip: 'Žinutės',
          onPressed: () => Navigator.of(context).pushNamed('/zinutes'),
          icon: const Icon(Icons.markunread_outlined),
        ),
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
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ..._defaultActions(context),
          ...actions,
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
