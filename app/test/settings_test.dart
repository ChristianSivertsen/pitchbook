import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/app_version.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/settings/settings_screen.dart';
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(AppShell))).brightness;

  testWidgets('M2-8: each setting changes the app at once and survives a '
      'restart', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final db = SvaDatabase.inMemory();
    addTearDown(db.close);
    await tester.runAsync(() => GradeRepository(db).seed());

    var container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    unawaitedPush(container, Routes.settings);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(brightness(tester), Brightness.light);

    Future<void> pick(String chip) async {
      await tester.tap(find.widgetWithText(FilterChip, chip));
      await tester.pumpAndSettle();
    }

    // Grades show in the system picked for their type.
    String show(String label, String system) =>
        container.read(gradeDisplayProvider)(label, system);
    expect(show('7-', 'nor'), '7-');
    await pick('French');
    final nor = gradeSystems.firstWhere((s) => s.key == 'nor');
    final french = gradeSystems.firstWhere((s) => s.key == 'french');
    expect(show('7-', 'nor'), convertGrade('7-', nor, french)!.label);
    await pick('V scale');

    await pick('Friends');
    await pick('Midnight sun');
    expect(brightness(tester), Brightness.dark);
    await pick('Norsk (bokmål)');
    expect(find.text('Innstillinger'), findsOneWidget);

    // A restart: a new app on the same database.
    container.dispose();
    await tester.pumpWidget(const SizedBox());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    unawaitedPush(container, Routes.settings);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
    expect(find.text('Innstillinger'), findsOneWidget);
    bool picked(String chip) => tester
        .widget<FilterChip>(find.widgetWithText(FilterChip, chip))
        .selected;
    expect(picked('Fransk'), isTrue);
    expect(picked('V-skala'), isTrue);
    expect(picked('Venner'), isTrue);
    expect(picked('Midnattssol'), isTrue);

    // Back to following the phone, for theme and then language.
    await tester.tap(find.widgetWithText(FilterChip, 'Følg telefonen').first);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
    await tester.tap(find.widgetWithText(FilterChip, 'Følg telefonen').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('M2-8: the licence page lists Fraunces and Inter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    registerSvaFontLicenses();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    unawaitedPush(container, Routes.settings);
    await tester.pumpAndSettle();
    expect(find.text(appVersion), findsOneWidget);

    await tester.tap(find.text('Licences'));
    // The licence page reads the licences in the background.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fraunces'), findsWidgets);
    expect(find.text('Inter'), findsWidgets);
  });

  test('M2-8: the version in settings is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    final version = line.substring('version:'.length).trim().split('+').first;
    expect(appVersion, version);
  });
}

/// Opens [path] the way a tap would, without waiting for the page.
void unawaitedPush(ProviderContainer container, String path) {
  // A pushed page's result is not needed here.
  // ignore: discarded_futures
  container.read(routerProvider).push(path);
}
