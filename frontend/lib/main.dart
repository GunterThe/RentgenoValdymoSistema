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
          color: scheme.surfaceContainerHighest,
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

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
    return AppScaffold(
      title: 'Pagrindinis',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
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
                        Text(
                          'Rentgeno valdymas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Greiti veiksmai ir paskutiniai įrašai',
                          style: TextStyle(fontSize: 13, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  _actionTile(
                    context: context,
                    icon: Icons.article_outlined,
                    title: 'Peržiūrėti įrašus',
                    subtitle: 'Atidarykite rentgeno įrašų sąrašą',
                    onTap: () => Navigator.of(context).pushNamed('/irasai'),
                  ),
                  const Divider(height: 1),
                  _actionTile(
                    context: context,
                    icon: Icons.science_outlined,
                    title: 'Peržiūrėti testus',
                    subtitle: 'Peržiūra ir testų vykdymas',
                    onTap: () => Navigator.of(context).pushNamed('/testai'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/testai'),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Testai'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/lokacijos'),
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Lokacijos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/sablonai'),
              icon: const Icon(Icons.layers_outlined),
              label: const Text('Šablonai'),
            ),
          ],
        ),
      ),
    );
  }
}
