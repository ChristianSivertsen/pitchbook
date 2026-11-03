import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_data/sva_data.dart';

/// A route as search returns it. Queries are faked here: their order and
/// matching are tested in sva_data.
RouteHit _hit(
  String id,
  String name, {
  String? grade,
  String? lastClimbed,
  int pitches = 1,
}) => (
  route: Route(
    id: id,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    visibility: 'public',
    areaId: 'kolsas',
    kind: 'outdoor',
    name: name,
    discipline: 'sport',
    pitchCount: pitches,
    lengthM: 18,
    status: 'open',
  ),
  grade: grade,
  crag: 'Kolsås',
  lastClimbed: lastClimbed,
  distanceKm: null,
  location: (lat: 59.92, lon: 10.5),
);

final _routes = <RouteHit>[
  _hit('r1', 'Hjemmebane', grade: '7-', lastClimbed: '2026-10-30'),
  _hit('r2', 'Bøyen', grade: '6', pitches: 2),
  _hit('r3', 'Fløyen direkte'),
];

void main() {
  late ProviderContainer container;

  Future<void> open(WidgetTester tester, String location) async {
    container = ProviderContainer(
      overrides: [
        routeSearchProvider.overrideWith(
          (ref, term) => Stream.value([
            for (final hit in _routes)
              if (hit.route.name!.toLowerCase().contains(term.toLowerCase()))
                hit,
          ]),
        ),
        routeHitProvider.overrideWith(
          (ref, id) async => _routes.where((h) => h.route.id == id).firstOrNull,
        ),
        routeDetailsProvider.overrideWith(
          (ref, id) async => {
            'rock_type': ['rock.basalt'],
            'hold': ['hold.crimp', 'hold.pinch'],
            'feature': ['feature.unknown_future_value'],
          },
        ),
        routeClimbsProvider.overrideWith(
          (ref, id) => Stream.value(
            id == 'r3'
                ? [
                    (
                      date: '2026-10-01',
                      ascent: _ascent('attempt', 1, feel: 'feel.hard'),
                      officialGrade: null,
                      personalGrade: null,
                    ),
                  ]
                : id == 'r1'
                ? [
                    (
                      date: '2026-10-30',
                      ascent: _ascent('redpoint', 3),
                      officialGrade: '7-',
                      personalGrade: '7',
                    ),
                    (
                      date: '2026-05-01',
                      ascent: _ascent('attempt', 2),
                      officialGrade: '6+',
                      personalGrade: null,
                    ),
                  ]
                : const [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('M2-1: typing in the search field updates the results', (
    tester,
  ) async {
    await open(tester, Routes.history);
    await tester.tap(find.byTooltip('Find a route'));
    await tester.pumpAndSettle();
    expect(find.text('Hjemmebane'), findsOneWidget);
    expect(find.text('Kolsås · Sport · 2 pitches'), findsOneWidget);
    expect(find.text('7-'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'øyen');
    await tester.pumpAndSettle();
    expect(find.text('Hjemmebane'), findsNothing);
    expect(find.text('Bøyen'), findsOneWidget);
    expect(find.text('Fløyen direkte'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('No routes match "xyz".'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bøy');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bøyen'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).state.matchedLocation,
      Routes.route('r2'),
    );
  });

  testWidgets("M2-1: route detail shows the route's data and your climbs", (
    tester,
  ) async {
    await open(tester, Routes.route('r1'));
    expect(find.text('Hjemmebane'), findsOneWidget);
    expect(find.text('7-'), findsOneWidget);
    expect(find.text('Kolsås'), findsOneWidget);
    expect(find.text('Sport · 18 m'), findsOneWidget);
    expect(find.text('Basalt'), findsOneWidget, reason: 'inherited rock');
    expect(find.text('Crimps'), findsOneWidget);
    expect(find.text('Pinches'), findsOneWidget);
    expect(find.textContaining('unknown'), findsNothing, reason: 'no raw keys');
    expect(find.text('30 Oct 2026'), findsOneWidget);
    expect(find.text('Redpoint'), findsOneWidget);
    expect(find.text('3 tries'), findsOneWidget);
    expect(find.text('Attempt'), findsOneWidget);

    container.read(routerProvider).go(Routes.route('r2'));
    await tester.pumpAndSettle();
    expect(find.text("You haven't logged this route yet."), findsOneWidget);
    expect(find.textContaining('Your grade'), findsNothing);

    container.read(routerProvider).go(Routes.route('gone'));
    await tester.pumpAndSettle();
    expect(find.text('This route is gone or private.'), findsOneWidget);
  });

  testWidgets('M2-4: route detail shows your grade next to the official one', (
    tester,
  ) async {
    await open(tester, Routes.route('r1'));
    expect(find.text('7-'), findsOneWidget, reason: 'the official grade');
    // Under the grade, and on the climb that set it.
    expect(find.text('Your grade: 7'), findsNWidgets(2));
    // The older climb was logged before the route went from 6+ to 7-.
    expect(find.text('graded 6+ then'), findsOneWidget);

    container.read(routerProvider).go(Routes.route('r3'));
    await tester.pumpAndSettle();
    expect(find.text('How it felt: Hard'), findsOneWidget);
  });
}

Ascent _ascent(String style, int tries, {String? feel}) => Ascent(
  id: 'a-$style',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  ownerId: 'local',
  visibility: 'private',
  sessionId: 's',
  routeId: 'r1',
  ordinal: 1,
  setting: 'outdoor',
  discipline: 'sport',
  ascentType: 'lead',
  style: style,
  tries: tries,
  feel: feel,
);
