import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../services/auth_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final String protectedRoute;

  const AuthGuard({
    super.key,
    required this.child,
    required this.protectedRoute,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  void _maybeNotifyMustChangePassword(BuildContext context) {
    if (!AuthService.instance.tryConsumeMustChangePasswordNotice()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Jūsų slaptažodis buvo atstatytas — rekomenduojama jį pasikeisti.'),
          action: SnackBarAction(
            label: 'Keisti',
            onPressed: () {
              Navigator.of(context).pushNamed('/paskyra');
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        if (!AuthService.instance.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (AuthService.instance.isAuthenticated) {
          _maybeNotifyMustChangePassword(context);
          return widget.child;
        }

        return LoginPage(nextRoute: widget.protectedRoute);
      },
    );
  }
}
