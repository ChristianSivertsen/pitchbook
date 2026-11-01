import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late AreaRepository areas;
  late RouteRepository routes;
  late GymWallRepository walls;
  late GymColourGradeRepository colours;
  late SessionRepository sessions;
  late AscentRepository ascents;
  var tick = 0;
  // Every write gets a later time, so updated_at changes are visible.
  DateTime clock() => DateTime.utc(2026, 11).add(Duration(seconds: tick++));

  setUp(() {
    db = SvaDatabase(NativeDatabase.memory());
    areas = AreaRepository(db, clock: clock);
    routes = RouteRepository(db, clock: clock);
    walls = GymWallRepository(db, clock: clock);
    colours = GymColourGradeRepository(db, clock: clock);
    sessions = SessionRepository(db, clock: clock);
    ascents = AscentRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<String> crag({String name = 'Kolsås', String user = 'me'}) =>
      areas.createPrivate(
        AreasCompanion(
          type: const Value('crag'),
          name: Value(name),
          countryCode: const Value('NO'),
        ),
        userId: user,
      );

  Future<String> route(String areaId, {String name = 'Hjemmebane'}) =>
      routes.createPrivate(
        RoutesCompanion(
          areaId: Value(areaId),
          kind: const Value('outdoor'),
          name: Value(name),
          discipline: const Value('sport'),
          status: const Value('open'),
        ),
        userId: 'me',
      );

  Future<String> session({String date = '2026-10-31'}) => sessions.create(
    SessionsCompanion(
      setting: const Value('outdoor'),
      localDate: Value(date),
      tz: const Value('Europe/Oslo'),
      visibility: const Value('friends'),
    ),
    userId: 'me',
  );

  Future<String> ascent(
    String sessionId,
    String routeId, {
    String style = 'redpoint',
    int tries = 2,
    int ordinal = 1,
  }) => ascents.create(
    AscentsCompanion(
      sessionId: Value(sessionId),
      routeId: Value(routeId),
      ordinal: Value(ordinal),
      ascentType: const Value('lead'),
      style: Value(style),
      tries: Value(tries),
    ),
    userId: 'me',
  );

  /// Create, read, update, soft delete and watch one row of [repo].
  Future<void> lifecycle<T extends Table, R extends DataClass>(
    Repository<T, R> repo,
    Future<String> Function() create,
    Insertable<R> changes,
    Object? Function(R row) changed,
    Object? expected,
  ) async {
    final id = await create();
    final seen = <R?>[];
    final subscription = repo.watch(id).listen(seen.add);

    Future<Object?> stamp() async =>
        (await db
                .customSelect(
                  'SELECT updated_at FROM ${repo.table.actualTableName} '
                  'WHERE id = ?',
                  variables: [Variable.withString(id)],
                )
                .getSingle())
            .data['updated_at'];

    final before = await stamp();
    await repo.update(id, changes, userId: 'me');
    final updated = (await repo.get(id))!;
    expect(changed(updated), expected, reason: repo.table.actualTableName);
    expect(await stamp(), isNot(before), reason: 'updated_at moves');

    await repo.softDelete(id, userId: 'me');
    expect(await repo.get(id), isNull);
    await pumpEventQueue();
    expect(seen.whereType<R>(), isNotEmpty);
    expect(seen.last, isNull, reason: 'watchers see the delete');
    await subscription.cancel();

    final kept = await db
        .customSelect(
          'SELECT deleted_at FROM ${repo.table.actualTableName} WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingle();
    expect(kept.data['deleted_at'], isNotNull, reason: 'rows are kept');
  }

  test(
    'M1-5: each repository creates, reads, updates, soft-deletes and watches',
    () async {
      final cragId = await crag();
      final routeId = await route(cragId);
      final sessionId = await session();

      await lifecycle(
        areas,
        crag,
        const AreasCompanion(name: Value('Kolsås vest')),
        (a) => a.name,
        'Kolsås vest',
      );
      await lifecycle(
        routes,
        () => route(cragId),
        const RoutesCompanion(name: Value('Bortebane')),
        (r) => r.name,
        'Bortebane',
      );
      await lifecycle(
        walls,
        () => walls.create(
          GymWallsCompanion(
            gymId: Value(cragId),
            name: const Value('Cave'),
            kind: const Value('boulder'),
          ),
          userId: 'me',
        ),
        const GymWallsCompanion(heightM: Value(4.5)),
        (w) => w.heightM,
        4.5,
      );
      await lifecycle(
        colours,
        () => colours.create(
          GymColourGradesCompanion(
            gymId: Value(cragId),
            sort: const Value(1),
            name: const Value('Blue'),
            colourHex: const Value('#2F6FD1'),
          ),
          userId: 'me',
        ),
        const GymColourGradesCompanion(routeMinScore: Value(15)),
        (c) => c.routeMinScore,
        15,
      );
      await lifecycle(
        sessions,
        session,
        const SessionsCompanion(title: Value('Last warm evening')),
        (s) => s.title,
        'Last warm evening',
      );
      await lifecycle(
        ascents,
        () => ascent(sessionId, routeId),
        const AscentsCompanion(tries: Value(4)),
        (a) => a.tries,
        4,
      );
    },
  );

  test('M1-5: list streams update when rows change', () async {
    final cragId = await crag();
    final mine = sessions.watchMine(userId: 'me');
    final inArea = routes.watchInArea(cragId, userId: 'me');
    expect(await mine.first, isEmpty);

    await session(date: '2026-10-01');
    await session();
    expect((await mine.first).map((s) => s.localDate), [
      '2026-10-31',
      '2026-10-01',
    ]);
    await route(cragId, name: 'B');
    await route(cragId, name: 'A');
    expect((await inArea.first).map((r) => r.name), ['A', 'B']);
  });

  test('M1-5: only the owner changes a row', () async {
    final cragId = await crag();
    final sessionId = await session();
    await (db.update(db.areas)..where((a) => a.id.equals(cragId))).write(
      const AreasCompanion(visibility: Value('public')),
    );

    expect(
      () => sessions.softDelete(sessionId, userId: 'someone else'),
      throwsA(isA<NotYourRow>()),
    );
    expect(
      () => areas.update(
        cragId,
        const AreasCompanion(name: Value('Mine now')),
        userId: 'me',
      ),
      throwsA(isA<NotYourRow>()),
      reason: 'public places change through moderated requests',
    );
    expect(
      () => ascent(sessionId, 'route'),
      throwsArgumentError,
      reason: 'the route must exist',
    );
    await expectLater(
      ascents.create(
        AscentsCompanion(
          sessionId: Value(sessionId),
          routeId: const Value('route'),
          ordinal: const Value(1),
          ascentType: const Value('lead'),
          style: const Value('flash'),
          tries: const Value(1),
        ),
        userId: 'someone else',
      ),
      throwsA(isA<NotYourRow>()),
    );
  });

  test(
    'M1-5: a session carries its visibility and deletes to its climbs',
    () async {
      final routeId = await route(await crag());
      final sessionId = await session();
      final ascentId = await ascent(sessionId, routeId);
      final created = (await ascents.get(ascentId))!;
      expect(
        (
          created.ownerId,
          created.visibility,
          created.setting,
          created.discipline,
        ),
        ('me', 'friends', 'outdoor', 'sport'),
      );
      await AttributeRepository(db).seed();
      await AttributeRepository(db)
          .setAscentAttribute(ascentId, 'tag', ['tag.pumpy'], userId: 'me');

      await sessions.setVisibility(sessionId, 'private', userId: 'me');
      expect((await ascents.get(ascentId))!.visibility, 'private');
      expect(
        (await db.select(db.ascentAttributes).getSingle()).visibility,
        'private',
      );

      await sessions.softDelete(sessionId, userId: 'me');
      expect(await ascents.get(ascentId), isNull);
      expect(
        (await db.select(db.ascentAttributes).getSingle()).deletedAt,
        isNotNull,
      );
    },
  );

  test(
    'M1-5: a route log is ordered by day and ordinal for the rules',
    () async {
      final routeId = await route(await crag());
      final later = await session();
      final earlier = await session(date: '2026-10-01');
      await ascent(later, routeId, tries: 4, ordinal: 2);
      await ascent(later, routeId, style: 'repeat', tries: 1, ordinal: 3);
      await ascent(earlier, routeId, style: 'attempt', tries: 3);
      final deleted = await session(date: '2026-09-01');
      await ascent(deleted, routeId, style: 'attempt', tries: 9);
      await sessions.softDelete(deleted, userId: 'me');

      final log = await ascents.routeLog(routeId, userId: 'me');
      expect(log, [
        (style: AscentStyle.attempt, tries: 3),
        (style: AscentStyle.redpoint, tries: 4),
        (style: AscentStyle.repeat, tries: 1),
      ]);
      expect(checkRouteLog(log), [isEmpty, isEmpty, isEmpty]);
    },
  );

  test("M1-5: search matches names and hides others' private places", () async {
    await crag();
    await crag(name: '100% Bærum');
    await crag(name: 'Secret boulder', user: 'someone else');
    final outdoor = await route(await crag(name: 'Flatanger'), name: 'Nordlys');
    await routes.createPrivate(
      const RoutesCompanion(
        areaId: Value('gym'),
        kind: Value('gym'),
        name: Value('Nordlys blue'),
        discipline: Value('boulder'),
        status: Value('open'),
      ),
      userId: 'me',
    );

    expect((await areas.search('ols', userId: 'me')).map((a) => a.name), [
      'Kolsås',
    ]);
    expect((await areas.search('%', userId: 'me')).map((a) => a.name), [
      '100% Bærum',
    ]);
    expect(await areas.search('secret', userId: 'me'), isEmpty);
    expect((await routes.search('nord', userId: 'me')).map((r) => r.id), [
      outdoor,
    ], reason: 'gym routes stay out of the outdoor list');
  });
}
