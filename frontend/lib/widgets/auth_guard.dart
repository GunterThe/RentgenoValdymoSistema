import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../services/auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String protectedRoute;

  const AuthGuard({
    super.key,
    required this.child,
    required this.protectedRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        // While we are reading secure storage on startup, don't flash login.
        if (!AuthService.instance.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (AuthService.instance.isAuthenticated) {
          return child;
        }

        return LoginPage(nextRoute: protectedRoute);
      },
    );
  }
}
