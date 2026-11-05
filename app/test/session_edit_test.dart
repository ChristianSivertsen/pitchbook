import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/shell/log_sheet.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';

/// Records the edit the sheet saves. Saving and the rules themselves are
/// tested in sva_data.
class _FakeLogger extends SessionLogger {
  new(super.db);

  SessionEdit? saved;

  @override
  Future<bool> editOutdoor(
    String sessionId,
    SessionEdit edit, {
    required String userId,
  }) async {
    saved = edit;
    return false;
  }
}

RouteHit _hit(String id, String name, {String discipline = 'sport'}) => (
  route: Route(
    id: id,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    visibility: 'public',
    areaId: 'kolsas',
    kind: 'outdoor',
    name: name,
    discipline: discipline,
    pitchCount: 1,
    status: 'open',
  ),
  grade: '7-',
  gradeSystem: 'nor',
  crag: 'Kolsås',
  lastClimbed: null,
  distanceKm: null,
  location: null,
);

final _session = Session(
  id: 's1',
  createdAt: DateTime.utc(2026, 10),
  updatedAt: DateTime.utc(2026, 10),
  ownerId: localUserId,
  visibility: 'private',
  setting: 'outdoor',
  localDate: '2026-10-01',
  tz: 'Europe/Oslo',
  locationHidden: false,
  title: 'Kveldsøkt',
);

final _climb = Ascent(
  id: 'a1',
  createdAt: DateTime.utc(2026, 10),
  updatedAt: DateTime.utc(2026, 10),
  ownerId: localUserId,
  visibility: 'private',
  sessionId: 's1',
  routeId: 'r1',
  ordinal: 1,
  ascentType: 'lead',
  style: 'flash',
  tries: 1,
  setting: 'outdoor',
  discipline: 'sport',
);

void main() {
  testWidgets('M2-6: the edit sheet adds and removes climbs', (tester) async {
    tester.view.physicalSize = const Size(1200, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = SvaDatabase.inMemory();
    final logger = _FakeLogger(db);
    final hits = {
      'r1': _hit('r1', 'Hjemmebane'),
      'b1': _hit('b1', 'Steinen', discipline: 'boulder'),
    };
    final container = ProviderContainer(
      overrides: [
        sessionLoggerProvider.overrideWithValue(logger),
        sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
        sessionPartnersProvider.overrideWith(
          (ref, id) => Stream.value(['Kari']),
        ),
        sessionAscentsProvider.overrideWith(
          (ref, id) => Stream.value([_climb]),
        ),
        routeHitProvider.overrideWith((ref, id) async => hits[id]),
        routeSearchProvider.overrideWith(
          (ref, term) => Stream.value(hits.values.toList()),
        ),
        routeLogUpToProvider.overrideWith((ref, key) async => const []),
        gradeSystemsProvider.overrideWith((ref) async => gradeSystems),
        mySessionsProvider.overrideWith((ref) => Stream.value([_session])),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    unawaited(container.read(routerProvider).push(Routes.session('s1')));
    await tester.pumpAndSettle();
    expect(find.text('With Kari'), findsOneWidget);

    await tester.tap(find.text('Edit session'));
    await tester.pumpAndSettle();
    expect(find.text('Edit session'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Kveldsøkt'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Hjemmebane'));
    await tester.pumpAndSettle();
    expect(find.text('1 climb is removed when you save.'), findsOneWidget);

    // The session page behind the sheet shows the same words.
    Finder inSheet(String text) =>
        find.descendant(of: find.byType(LogSheet), matching: find.text(text));
    await tester.tap(inSheet('Steinen'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Flash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final edit = logger.saved!;
    expect(edit.removed, {'a1'});
    expect(edit.added.single.routeId, 'b1');
    expect(edit.added.single.style, AscentStyle.flash);
    expect(edit.title, 'Kveldsøkt');
    expect(edit.partners.map((p) => p.trim()), ['Kari']);
    expect(find.text('Changes saved'), findsOneWidget);
  });
}
