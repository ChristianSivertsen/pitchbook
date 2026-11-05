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

/// Records what the gym form saves. Storage and its checks are tested in
/// sva_data.
class _FakeGyms extends GymEditor {
  new(super.db, {this.existing, this.fail = false});

  final GymSetup? existing;
  final bool fail;
  NewGym? gym;
  List<WallDraft>? walls;
  String? called;

  @override
  Future<String> addGym(
    NewGym gym, {
    required List<WallDraft> walls,
    required String userId,
  }) async {
    if (fail) throw StateError('disk full');
    this.gym = gym;
    this.walls = walls;
    called = 'addGym';
    return 'g1';
  }

  @override
  Future<void> updateGym(
    String gymId,
    NewGym gym, {
    required List<WallDraft> walls,
    required String userId,
  }) async {
    this.gym = gym;
    this.walls = walls;
    called = 'updateGym';
  }

  @override
  Future<void> saveWalls(
    String gymId, {
    required List<WallDraft> walls,
    required String userId,
  }) async {
    this.walls = walls;
    called = 'saveWalls';
  }

  @override
  Future<GymSetup?> setup(String gymId, {required String userId}) async =>
      existing;
}

Area _gym({String createdBy = localUserId, String visibility = 'private'}) =>
    Area(
      id: 'g1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      createdBy: createdBy,
      visibility: visibility,
      type: 'gym',
      name: 'Klatreverket',
      countryCode: 'NO',
      locationHidden: false,
    );

GymWall _wall(String id, String name, String kind, double height) => GymWall(
  id: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  ownerId: localUserId,
  gymId: 'g1',
  name: name,
  heightM: height,
  angle: 'angle.vertical',
  kind: kind,
  sort: 0,
);

void main() {
  late _FakeGyms gyms;

  /// Opens settings, and the gym form for [existing] when given.
  Future<void> open(
    WidgetTester tester, {
    GymSetup? existing,
    bool fail = false,
  }) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = SvaDatabase.inMemory();
    addTearDown(db.close);
    gyms = _FakeGyms(db, existing: existing, fail: fail);
    final container = ProviderContainer(
      overrides: [
        gymEditorProvider.overrideWithValue(gyms),
        gymsProvider.overrideWith((ref) => Stream.value(const [])),
        settingsProvider.overrideWith((ref) => Stream.value(const Settings())),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    // A page's result is not needed here.
    unawaited(container.read(routerProvider).push(Routes.settings));
    await tester.pumpAndSettle();
    if (existing != null) {
      unawaited(container.read(routerProvider).push(Routes.gym('g1')));
      await tester.pumpAndSettle();
    }
  }

  Finder field(String text) => find.widgetWithText(TextFormField, text);

  testWidgets('M3-1: a gym with 4 walls is set up in under 2 minutes', (
    tester,
  ) async {
    await open(tester);
    // Each tap or typed field is one step: a handful is well under
    // 2 minutes.
    var steps = 0;
    Future<void> tap(Finder target) async {
      steps++;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> type(Finder target, String text) async {
      steps++;
      await tester.enterText(target, text);
      await tester.pumpAndSettle();
    }

    await tap(find.text('Add a gym'));
    expect(find.byType(GymFormScreen), findsOneWidget);
    await type(field('Name'), 'Klatreverket');
    await tap(find.text('Add a wall'));
    await tap(find.text('Add a wall'));
    await type(field('Wall 4'), 'Board');
    await tap(find.text('Save gym'));

    expect(steps, lessThanOrEqualTo(6));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(gyms.called, 'addGym');
    expect(gyms.gym!.name, 'Klatreverket');
    expect(gyms.gym!.grading, 'colour');
    expect(gyms.walls!.map((w) => (w.name, w.kind, w.heightM, w.angle)), [
      ('Main wall', 'rope', 14.0, 'angle.vertical'),
      ('Boulder area', 'boulder', 4.5, 'angle.overhang'),
      ('Wall 3', 'boulder', 4.5, 'angle.vertical'),
      ('Board', 'boulder', 4.5, 'angle.vertical'),
    ]);
  });

  testWidgets('M3-1: the wall editor changes, adds and removes walls', (
    tester,
  ) async {
    await open(
      tester,
      existing: (
        gym: _gym(),
        grading: 'standard',
        walls: [
          _wall('w1', 'Lead wall', 'rope', 15),
          _wall('w2', 'Cave', 'boulder', 4),
        ],
      ),
    );
    expect(find.text('Edit gym'), findsOneWidget);
    expect(field('Lead wall'), findsOneWidget);

    // A height typed with a decimal comma carries over to a new wall.
    await tester.enterText(field('4'), '4,5');
    await tester.tap(find.text('Add a wall'));
    await tester.pumpAndSettle();
    // The remove button follows the typed name.
    await tester.enterText(field('Wall 3'), 'Board');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove Board'), findsOneWidget);
    final cave = find.ancestor(of: field('Cave'), matching: find.byType(Card));
    await tester.tap(
      find.descendant(
        of: cave,
        matching: find.widgetWithText(FilterChip, 'Roof'),
      ),
    );
    await tester.tap(find.byTooltip('Remove Lead wall'));
    await tester.pumpAndSettle();
    // Adding after a removal does not repeat a name.
    await tester.tap(find.text('Add a wall'));
    await tester.pumpAndSettle();
    expect(field('Wall 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Wall 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save gym'));
    await tester.pumpAndSettle();

    expect(gyms.called, 'updateGym');
    expect(gyms.gym!.grading, 'standard');
    expect(gyms.walls!.map((w) => (w.id, w.name, w.heightM, w.angle)), [
      ('w2', 'Cave', 4.5, 'angle.roof'),
      (null, 'Board', 4.5, 'angle.vertical'),
    ]);
  });

  testWidgets('M3-1: the gym form checks its fields and keeps one wall', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Add a gym'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Main wall'), ' ');
    await tester.enterText(field('14'), '0,5');
    await tester.tap(find.text('Save gym'));
    await tester.pumpAndSettle();
    expect(find.text('Give the gym a name.'), findsOneWidget);
    expect(find.text('Give the wall a name.'), findsOneWidget);
    expect(
      find.text('Use a height from 1 to 60 m, or leave it empty.'),
      findsOneWidget,
    );
    expect(gyms.called, isNull, reason: 'nothing saved');

    // With one wall left, it has no remove button.
    await tester.tap(find.byTooltip('Remove Boulder area'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(IconButton)),
      findsNothing,
    );
  });

  testWidgets('M3-1: on a shared gym only your walls are saved', (
    tester,
  ) async {
    await open(
      tester,
      existing: (
        gym: _gym(createdBy: 'someone else', visibility: 'public'),
        grading: 'colour',
        walls: const [],
      ),
    );
    expect(
      find.text('This gym is shared, so only your walls can be changed here.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(field('Klatreverket')).enabled,
      isFalse,
    );
    await tester.tap(find.text('Add a wall'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save gym'));
    await tester.pumpAndSettle();
    expect(gyms.called, 'saveWalls');
    expect(gyms.walls!.single.name, 'Wall 1');
  });

  testWidgets('M3-1: a gym that cannot be saved says so', (tester) async {
    await open(tester, fail: true);
    await tester.tap(find.text('Add a gym'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Klatreverket');
    await tester.tap(find.text('Save gym'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't save. Check the fields and try again."),
      findsOneWidget,
    );
    expect(find.byType(GymFormScreen), findsOneWidget);
  });
}
