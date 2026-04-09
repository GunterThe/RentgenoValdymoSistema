// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  testWidgets('App builds and shows auth gate', (WidgetTester tester) async {
    // We are not calling `main()` in widget tests; AuthService.init() is async.
    // Ensure it starts in non-initialized state so we can assert the loading UI.
    expect(AuthService.instance.isInitialized, isFalse);

    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);

    // AuthGuard shows a loading indicator while AuthService initializes.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
