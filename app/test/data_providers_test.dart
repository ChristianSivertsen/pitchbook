import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva_data/sva_data.dart';

void main() {
  test('M1-5: providers stream repository data to screens', () async {
    final db = SvaDatabase.inMemory();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final seen = <List<Session>>[];
    container.listen(
      mySessionsProvider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await container
        .read(sessionRepositoryProvider)
        .create(
          const SessionsCompanion(
            setting: Value('indoor'),
            localDate: Value('2026-10-29'),
            tz: Value('Europe/Oslo'),
            visibility: Value('friends'),
          ),
          userId: container.read(currentUserIdProvider),
        );
    await pumpEventQueue();
    expect(seen.last.single.localDate, '2026-10-29');
  });

  test("M2-7: a session's tags are its climbs' features, holds and tags, "
      'without repeats', () async {
    final db = SvaDatabase.inMemory();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final me = container.read(currentUserIdProvider);
    final attributes = container.read(attributeRepositoryProvider);
    await attributes.seed();
    final cragId = await container
        .read(areaRepositoryProvider)
        .createPrivate(
          const AreasCompanion(
            type: Value('crag'),
            name: Value('Kolsås'),
            countryCode: Value('NO'),
          ),
          userId: me,
        );
    Future<String> route(
      String name,
      List<String> features,
      String hold,
    ) async {
      final id = await container
          .read(routeRepositoryProvider)
          .createPrivate(
            RoutesCompanion(
              areaId: Value(cragId),
              kind: const Value('outdoor'),
              name: Value(name),
              discipline: const Value('sport'),
              status: const Value('open'),
            ),
            userId: me,
          );
      await attributes.setRouteAttribute(id, 'feature', features, userId: me);
      await attributes.setRouteAttribute(id, 'hold', [hold], userId: me);
      return id;
    }

    final sessionId = await container
        .read(sessionRepositoryProvider)
        .create(
          const SessionsCompanion(
            setting: Value('outdoor'),
            localDate: Value('2026-10-17'),
            tz: Value('Europe/Oslo'),
            visibility: Value('private'),
          ),
          userId: me,
        );
    Future<String> climb(String routeId, int ordinal) => container
        .read(ascentRepositoryProvider)
        .create(
          AscentsCompanion(
            sessionId: Value(sessionId),
            routeId: Value(routeId),
            ordinal: Value(ordinal),
            ascentType: const Value('lead'),
            style: const Value('attempt'),
            tries: const Value(1),
          ),
          userId: me,
        );
    final first = await climb(
      await route('Hjemmebane', ['feature.face'], 'hold.crimp'),
      1,
    );
    await attributes.setAscentAttribute(first, 'tag', [
      'tag.pumpy',
    ], userId: me);
    await climb(
      await route('Kveldsløftet', [
        'feature.face',
        'feature.corner',
      ], 'hold.jug'),
      2,
    );

    final sub = container.listen(sessionTagsProvider(sessionId), (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(sessionTagsProvider(sessionId).future), [
      'feature.face',
      'hold.crimp',
      'tag.pumpy',
      'feature.corner',
      'hold.jug',
    ]);
  });
}
