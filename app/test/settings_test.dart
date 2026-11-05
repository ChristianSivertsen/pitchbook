import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/app_version.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/route_search_screen.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/settings/settings_screen.dart';
import 'package:sva/src/shell/app_shell.dart';
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
    await tester.runAsync(() async {
      await GradeRepository(db).seed();
      await AttributeRepository(db).seed();
      final editor = RouteEditor(db);
      final crag = await editor.addCrag(
        const NewCrag(name: 'Kolsås', countryCode: 'NO'),
        userId: localUserId,
      );
      await editor.addRoute(
        NewRoute(
          areaId: crag,
          name: 'Hjemmebane',
          discipline: 'sport',
          gradeId: seedId('grade:nor:7-'),
        ),
        userId: localUserId,
      );
    });

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

    // Grades show in the system picked for their type, here in route
    // search.
    final hjemmebane = find.descendant(
      of: find.widgetWithText(RouteHitTile, 'Hjemmebane'),
      matching: find.byType(SvaGradeBadge),
    );
    Future<String> searchedGrade() async {
      unawaitedPush(container, Routes.routeSearch);
      // Search runs real queries on the database: give them real time.
      for (var i = 0; i < 5 && hjemmebane.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
      }
      final grade = tester.widget<SvaGradeBadge>(hjemmebane).label;
      container.read(routerProvider).pop();
      await tester.pumpAndSettle();
      return grade;
    }

    final asLogged = await searchedGrade();
    await pick('French');
    expect(await searchedGrade(), isNot(asLogged));
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

  testWidgets('M2-8: a setting that cannot be saved says so', (tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => Stream.value(const Settings())),
        settingsRepositoryProvider.overrideWithValue(_FailingSettings()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    unawaitedPush(container, Routes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Midnight sun'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save the setting. Try again."), findsOneWidget);
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

/// Settings whose saves fail, as a full disk would.
class _FailingSettings extends SettingsRepository {
  new() : super(SvaDatabase.inMemory());

  @override
  Future<void> setTheme(String userId, String theme) async =>
      throw StateError('disk full');
}
