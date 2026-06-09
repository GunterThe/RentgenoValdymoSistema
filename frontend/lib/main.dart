import 'package:flutter/material.dart';
import 'pages/irasai_page.dart';
import 'pages/lokacijos_page.dart';
import 'pages/sablonai_page.dart';
import 'pages/testai_page.dart';
import 'pages/login_page.dart';
import 'pages/paskyra_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/chat_page.dart';
import 'services/auth_service.dart';
import 'services/api.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/auth_guard.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  // Use hash-based routing so links like /#/reset-password?token=... work
  setUrlStrategy(const HashUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bolder, modern theme: vibrant seed and pronounced surfaces/buttons.
    const seed = Color(0xFF6A1B9A); // deep purple accent
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      // keep contrast high so components pop on desktop and mobile
      contrastLevel: 0.4,
    );
    return MaterialApp(
      title: 'Rentgeno Valdymas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 2,
          scrolledUnderElevation: 4,
          surfaceTintColor: scheme.surfaceTint,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: scheme.onSurface,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          color: scheme.surfaceContainer,
          surfaceTintColor: scheme.surfaceTint,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          contentTextStyle: TextStyle(color: scheme.onInverseSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: scheme.primary.withAlpha((0.9 * 255).round())),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onSurface),
          bodyLarge: TextStyle(fontSize: 16, color: scheme.onSurface),
          bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
      ),
      routes: {
        '/login': (_) => AuthService.instance.isAuthenticated
            ? const MainPage()
            : const LoginPage(),
        '/': (_) => const AuthGuard(protectedRoute: '/', child: MainPage()),
        '/reset-password': (_) => const ResetPasswordPage(),
        '/paskyra': (_) =>
          const AuthGuard(protectedRoute: '/paskyra', child: PaskyraPage()),
        '/irasai': (_) =>
            const AuthGuard(protectedRoute: '/irasai', child: IrasaiPage()),
        '/testai': (_) =>
            const AuthGuard(protectedRoute: '/testai', child: TestaiPage()),
        '/lokacijos': (_) => const AuthGuard(
          protectedRoute: '/lokacijos',
          child: LokacijosPage(),
        ),
        '/sablonai': (_) =>
            const AuthGuard(protectedRoute: '/sablonai', child: SablonaiPage()),
        '/pokalbiai': (_) =>
            const AuthGuard(protectedRoute: '/pokalbiai', child: ChatPage()),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        final uri = Uri.parse(name);
        if (uri.path == '/reset-password') {
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ResetPasswordPage(tokenFromArgs: token),
          );
        }
        return null;
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _loading = true;
  int _irasaiCount = 0;
  int _testaiCount = 0;
  int _usersCount = 0;
  List<Map<String, dynamic>> _recentIrasai = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() => _loading = true);
      final irasai = await Api.fetchIrasai();
      final testai = await Api.fetchTestai();
      final naud = await Api.fetchNaudotojai();

      final irasaiList = (irasai).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      irasaiList.sort((a, b) {
        final da = DateTime.tryParse((a['pradzia'] ?? a['Pradzia'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse((b['pradzia'] ?? b['Pradzia'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      setState(() {
        _irasaiCount = irasaiList.length;
        _testaiCount = (testai).length;
        _usersCount = (naud).length;
        _recentIrasai = irasaiList.take(5).toList();
      });
    } catch (e) {
      // ignore - keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget statsTile(String label, String value, IconData icon) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.onPrimary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ],
          ),
        );

    return AppScaffold(
      title: 'Pagrindinis',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primaryContainer.withAlpha(31), cs.surface],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 900;

          // Shared children used for both mobile and desktop (stacked column)
          final children = <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rentgeno valdymas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                        SizedBox(height: 2),
                        Text('Greiti veiksmai ir paskutiniai įrašai', style: TextStyle(fontSize: 13, height: 1.25)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: cs.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: 220, child: _actionTile(context: context, icon: Icons.article_outlined, title: 'Įrašai', subtitle: 'Peržiūrėti įrašus', onTap: () => Navigator.of(context).pushNamed('/irasai'))),
                    SizedBox(width: 220, child: _actionTile(context: context, icon: Icons.science_outlined, title: 'Testai', subtitle: 'Peržiūra ir testų vykdymas', onTap: () => Navigator.of(context).pushNamed('/testai'))),
                    SizedBox(width: 220, child: _actionTile(context: context, icon: Icons.place_outlined, title: 'Lokacijos', subtitle: 'Valdyti lokacijas', onTap: () => Navigator.of(context).pushNamed('/lokacijos'))),
                    SizedBox(width: 220, child: _actionTile(context: context, icon: Icons.layers_outlined, title: 'Šablonai', subtitle: 'Tvarkyti šablonus', onTap: () => Navigator.of(context).pushNamed('/sablonai'))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: statsTile('Įrašai', _loading ? '...' : '$_irasaiCount', Icons.article_outlined)),
                const SizedBox(width: 12),
                Expanded(child: statsTile('Testai', _loading ? '...' : '$_testaiCount', Icons.science_outlined)),
                const SizedBox(width: 12),
                Expanded(child: statsTile('Vartotojai', _loading ? '...' : '$_usersCount', Icons.group_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: cs.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('Naujausi įrašai', style: TextStyle(fontWeight: FontWeight.w800)),
                    trailing: TextButton(onPressed: () => Navigator.of(context).pushNamed('/irasai'), child: const Text('Peržiūrėti visus')),
                  ),
                  const Divider(height: 1),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_recentIrasai.isEmpty)
                    const ListTile(title: Text('Nėra naujų įrašų'))
                  else
                    for (var i = 0; i < _recentIrasai.length; i++)
                      ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text((_recentIrasai[i]['pavadinimas'] ?? _recentIrasai[i]['Pavadinimas'] ?? 'Įrašas').toString()),
                        subtitle: Text('Pradžia: ${(_recentIrasai[i]['pradzia'] ?? _recentIrasai[i]['Pradzia'] ?? '').toString().split('T').first}'),
                        onTap: () => Navigator.of(context).pushNamed('/irasai'),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: cs.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pranešimai', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Visos sistemos veiklos santrauka pateikiama čia.', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: isWide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    children: children,
                  ),
          );
        }),
      ),
    ),
    );
  }
}
