import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/gyms/gym_form_screen.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/settings/settings_screen.dart';
import 'package:sva_data/sva_data.dart';

void main() {
  testWidgets('M3-1: a gym with 4 walls is set up in a few steps, and its '
      'walls can be edited', (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = SvaDatabase.inMemory();
    addTearDown(db.close);
    await tester.runAsync(() => AttributeRepository(db).seed());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    // A page's result is not needed here.
    unawaited(container.read(routerProvider).push(Routes.settings));
    await tester.pumpAndSettle();

    /// Lets the database work in real time, then draws the result.
    Future<void> settle() async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
    }

    // Each tap or typed field counts as one step: under 2 minutes is a
    // handful of them.
    var steps = 0;
    Future<void> tap(Finder target) async {
      steps++;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await settle();
    }

    Future<void> type(Finder field, String text) async {
      steps++;
      await tester.enterText(field, text);
      await tester.pumpAndSettle();
    }

    await tap(find.text('Add a gym'));
    expect(find.byType(GymFormScreen), findsOneWidget);
    await type(find.widgetWithText(TextFormField, 'Name'), 'Klatreverket');
    await tap(find.text('Add a wall'));
    await tap(find.text('Add a wall'));
    await type(find.widgetWithText(TextFormField, 'Wall 4'), 'Board');
    await tap(find.text('Save gym'));

    expect(steps, lessThanOrEqualTo(6));
    expect(find.byType(SettingsScreen), findsOneWidget);
    final gym = (await tester.runAsync(
      () =>
          (db.select(db.areas)..where((a) => a.type.equals('gym'))).getSingle(),
    ))!;
    final setup = (await tester.runAsync(
      () => GymEditor(db).setup(gym.id, userId: localUserId),
    ))!;
    expect(setup.gym.name, 'Klatreverket');
    expect(setup.grading, 'colour');
    expect(setup.walls.map((w) => (w.name, w.kind, w.heightM, w.angle)), [
      ('Main wall', 'rope', 14.0, 'angle.vertical'),
      ('Boulder area', 'boulder', 4.5, 'angle.overhang'),
      ('Wall 3', 'boulder', 4.5, 'angle.vertical'),
      ('Board', 'boulder', 4.5, 'angle.vertical'),
    ]);

    // Open it again from settings: rename a wall, make it steeper and
    // remove another.
    await tap(find.text('Klatreverket'));
    expect(find.widgetWithText(TextFormField, 'Board'), findsOneWidget);
    await type(find.widgetWithText(TextFormField, 'Wall 3'), 'Cave');
    final caveCard = find.ancestor(
      of: find.widgetWithText(TextFormField, 'Cave'),
      matching: find.byType(Card),
    );
    await tap(
      find.descendant(
        of: caveCard,
        matching: find.widgetWithText(FilterChip, 'Roof'),
      ),
    );
    await tap(find.byTooltip('Remove Board'));
    await tap(find.text('Save gym'));

    final edited = (await tester.runAsync(
      () => GymEditor(db).setup(gym.id, userId: localUserId),
    ))!;
    expect(edited.walls.map((w) => (w.name, w.angle)), [
      ('Main wall', 'angle.vertical'),
      ('Boulder area', 'angle.overhang'),
      ('Cave', 'angle.roof'),
    ]);
  });
}
