import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'chat_widget.dart';

void showPlaceholder(BuildContext context, String title) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$title - dar neįgyvendinta')),
  );
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
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

  static const _items = <_NavItem>[
    _NavItem('Pagrindinis', Icons.home_outlined, '/'),
    _NavItem('Įrašai', Icons.article_outlined, '/irasai'),
    _NavItem('Testai', Icons.science_outlined, '/testai'),
    _NavItem('Lokacijos', Icons.place_outlined, '/lokacijos'),
    _NavItem('Šablonai', Icons.layers_outlined, '/sablonai'),
  ];

  List<Widget> _defaultActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Paskyra',
        onPressed: () => Navigator.of(context).pushNamed('/paskyra'),
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
      PopupMenuButton<int>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 0, child: Text('Nustatymai')),
        ],
        onSelected: (_) => showPlaceholder(context, 'Nustatymai'),
      ),
    ];
  }

  Widget _withFabScrollPadding(BuildContext context, Widget child) {
    if (floatingActionButton == null) return child;
    final bottom = 88.0 + MediaQuery.viewPaddingOf(context).bottom;
    return Padding(padding: EdgeInsets.only(bottom: bottom), child: child);
  }

  int _routeToIndex(String? route) {
    if (route == null) return 0;
    final i = _items.indexWhere((e) => e.route == route);
    return i < 0 ? 0 : i;
  }

  void _navigateTo(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selectedIndex = _routeToIndex(currentRoute);

    final navRail = NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => _navigateTo(context, _items[i].route),
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_information_outlined, color: cs.onPrimary),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      destinations: _items
          .map((e) => NavigationRailDestination(
                icon: Icon(e.icon),
                selectedIcon: Icon(e.icon),
                label: Text(e.label),
              ))
          .toList(),
    );

    final drawer = Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: cs.primary, child: Icon(Icons.person, color: cs.onPrimary)),
              title: const Text('Paskyra'),
              subtitle: const Text('Peržiūrėti paskyrą'),
              onTap: () => Navigator.of(context).pushNamed('/paskyra'),
            ),
            const Divider(),
            ..._items.map((it) => ListTile(
                  leading: Icon(it.icon),
                  title: Text(it.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateTo(context, it.route);
                  },
                )),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Atsijungti'),
              onTap: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              },
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      drawer: isWide ? null : drawer,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: Row(
          children: [
            if (!isWide)
              Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            IconButton(onPressed: () => showPlaceholder(context, 'Paieška'), icon: const Icon(Icons.search)),
            ..._defaultActions(context),
          ],
        ),
      ),
      body: _withFabScrollPadding(
        context,
        Stack(
          children: [
            Row(
              children: [
                if (isWide)
                  Container(
                    width: 92,
                    color: cs.surfaceContainerHighest.withAlpha(10),
                    child: navRail,
                  ),
                Expanded(child: body),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ChatWidget(),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex > 2 ? 2 : selectedIndex,
              onTap: (i) {
                // Map bottom nav to a few primary routes
                final route = i == 0 ? '/' : i == 1 ? '/irasai' : '/testai';
                _navigateTo(context, route);
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Pagrindinis'),
                BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Įrašai'),
                BottomNavigationBarItem(icon: Icon(Icons.science_outlined), label: 'Testai'),
              ],
            ),
    );
  }
}
