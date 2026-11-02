import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';

/// Records what the form saves instead of writing it. Saving itself is
/// tested in sva_data.
class _FakeEditor extends RouteEditor {
  new(super.db);

  NewRoute? saved;

  @override
  Future<String> addRoute(NewRoute route, {required String userId}) async {
    saved = route;
    return 'new-route';
  }
}

final _kolsas = Area(
  id: 'kolsas',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  visibility: 'public',
  type: 'crag',
  name: 'Kolsås',
  countryCode: 'NO',
  rockType: 'rock.basalt',
  locationHidden: false,
);

void main() {
  testWidgets('M2-2: the route form checks input and saves it', (tester) async {
    // Tall enough that the whole form is built without scrolling.
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = SvaDatabase.inMemory();
    final editor = _FakeEditor(db);
    final container = ProviderContainer(
      overrides: [
        routeEditorProvider.overrideWithValue(editor),
        routePlacesProvider.overrideWith((ref) => Stream.value([_kolsas])),
        gradeSystemsProvider.overrideWith((ref) async => gradeSystems),
        routeHitProvider.overrideWith((ref, id) async => null),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    container.read(routerProvider).go(Routes.routeNew);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();
    expect(find.text('Give the route a name.'), findsOneWidget);
    expect(find.text('Pick the crag the route is in.'), findsOneWidget);
    expect(editor.saved, isNull);

    Finder field(String label) =>
        find.widgetWithText(TextFormField, label).first;
    await tester.enterText(field('Name'), 'Nordveggen direkte');
    await tester.tap(find.text('Crag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kolsås').last);
    await tester.pumpAndSettle();
    expect(find.text('Rock type comes from the crag: Basalt.'), findsOneWidget);

    await tester.tap(find.text('Trad'));
    await tester.enterText(field('Length in metres'), 'lang');
    await tester.enterText(field('Pitches'), '2');
    await tester.pumpAndSettle();
    expect(find.text('Pitch 1'), findsOneWidget);
    expect(find.text('Pitch 2'), findsOneWidget);
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 1 to 3000.'), findsOneWidget);
    expect(editor.saved, isNull);

    await tester.enterText(field('Length in metres'), '62,5');
    await tester.tap(find.text('Grade (Norwegian)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6+').last);
    await tester.pumpAndSettle();
    for (final chip in ['Crimps', 'Jugs', 'Bolted', '60 m']) {
      await tester.tap(find.text(chip));
      await tester.pump();
    }
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();

    final saved = editor.saved!;
    expect(saved.name, 'Nordveggen direkte');
    expect(saved.areaId, 'kolsas');
    expect(saved.discipline, 'trad');
    expect(saved.gradeId, seedId('grade:nor:6+'));
    expect(saved.lengthM, 62.5);
    expect(saved.pitches, hasLength(2));
    expect(saved.holds, ['hold.crimp', 'hold.jug']);
    expect(saved.protection, 'protection.bolted');
    expect(saved.ropeLengthM, 60);
    expect(
      container.read(routerProvider).state.matchedLocation,
      Routes.route('new-route'),
      reason: 'opens the new route',
    );
  });
}
