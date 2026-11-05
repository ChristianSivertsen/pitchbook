import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva_data/sva_data.dart' show Settings;
import 'package:sva_ui/sva_ui.dart';

void main() {
  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(AppShell))).brightness;

  testWidgets('M0-4: the app starts with the Sva theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SvaApp()));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(AppShell)));
    expect(theme.extension<SvaColors>(), isNotNull);
  });

  testWidgets('M0-4: follows the system setting by default', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const ProviderScope(child: SvaApp()));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);
  });

  testWidgets('M0-4: switching between dark and light updates the app', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = StreamController<Settings>();
    addTearDown(settings.close);
    final container = ProviderContainer(
      overrides: [settingsProvider.overrideWith((ref) => settings.stream)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    await tester.pumpAndSettle();

    settings.add(const Settings(theme: 'midnight'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(AppShell))).scaffoldBackgroundColor,
      SvaColors.midnight.background,
    );

    // With the system in dark mode, choosing light must override it.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    settings.add(const Settings(theme: 'daylight'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);
  });

  testWidgets('M0-4: debug builds can open the token preview', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    container.read(routerProvider).go(Routes.tokenPreview);
    await tester.pumpAndSettle();

    expect(find.byType(SvaTokenPreview), findsOneWidget);
  });
}
