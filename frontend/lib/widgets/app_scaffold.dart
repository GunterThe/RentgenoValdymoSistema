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
    return [
      IconButton(
        tooltip: 'Paskyra',
        onPressed: () => showPlaceholder(context, 'Paskyra'),
        icon: const Icon(Icons.person_outline),
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
      ),
      IconButton(
        tooltip: 'Supakavimas',
        onPressed: () => showPlaceholder(context, 'Supakavimas'),
        icon: const Icon(Icons.inventory_2_outlined),
      ),
      IconButton(
        tooltip: 'Išvežimas',
        onPressed: () => showPlaceholder(context, 'Išvežimas'),
        icon: const Icon(Icons.local_shipping_outlined),
      ),
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
