import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

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
    db = SvaDatabase.inMemory();
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

  Future<String> route(
    String areaId, {
    String name = 'Hjemmebane',
    String user = 'me',
  }) => routes.createPrivate(
    RoutesCompanion(
      areaId: Value(areaId),
      kind: const Value('outdoor'),
      name: Value(name),
      discipline: const Value('sport'),
      status: const Value('open'),
    ),
    userId: user,
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

  test(
    'M1-5: each repository creates, reads, updates, soft-deletes and watches',
    () async {
      final cragId = await crag();
      final routeId = await route(cragId);
      final sessionId = await session();

      await lifecycle(
        db,
        areas,
        crag,
        const AreasCompanion(name: Value('Kolsås vest')),
        (a) => a.name,
        'Kolsås vest',
      );
      await lifecycle(
        db,
        routes,
        () => route(cragId),
        const RoutesCompanion(name: Value('Bortebane')),
        (r) => r.name,
        'Bortebane',
      );
      await lifecycle(
        db,
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
        db,
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
        db,
        sessions,
        session,
        const SessionsCompanion(title: Value('Last warm evening')),
        (s) => s.title,
        'Last warm evening',
      );
      await lifecycle(
        db,
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
    final sessionId = await session(date: '2026-10-01');

    final mine = await emissions(sessions.watchMine(userId: 'me'), session);
    expect(mine.length, greaterThan(1), reason: 'the open stream emitted');
    expect(mine.last.map((s) => s.localDate), ['2026-10-31', '2026-10-01']);

    final inArea = await emissions(
      routes.watchInArea(cragId, userId: 'me'),
      () async {
        await route(cragId, name: 'B');
        await route(cragId, name: 'A');
        await route(cragId, name: 'Theirs', user: 'someone else');
      },
    );
    expect(inArea.last.map((r) => r.name), ['A', 'B']);

    final routeId = inArea.last.first.id;
    final inSession = await emissions(
      ascents.watchInSession(sessionId),
      () async {
        await ascent(sessionId, routeId, style: 'repeat', ordinal: 2);
        await ascent(sessionId, routeId, style: 'flash', tries: 1);
      },
    );
    expect(inSession.last.map((a) => a.ordinal), [1, 2]);

    final top = await emissions(
      areas.watchChildren(null, userId: 'me'),
      () => crag(name: 'Secret', user: 'someone else'),
    );
    expect(top.last.map((a) => a.name), ['Kolsås'], reason: 'others hidden');
    final children = await emissions(
      areas.watchChildren(cragId, userId: 'me'),
      () => areas.createPrivate(
        AreasCompanion(
          parentId: Value(cragId),
          type: const Value('sector'),
          name: const Value('Vestveggen'),
          countryCode: const Value('NO'),
        ),
        userId: 'me',
      ),
    );
    expect(children.last.map((a) => a.name), ['Vestveggen']);

    final gymWalls = await emissions(
      walls.watchInGym(cragId, userId: 'me'),
      () => walls.create(
        GymWallsCompanion(
          gymId: Value(cragId),
          name: const Value('Cave'),
          kind: const Value('boulder'),
        ),
        userId: 'me',
      ),
    );
    expect(gymWalls.last.map((w) => w.name), ['Cave']);
    final scale = await emissions(
      colours.watchForGym(cragId, userId: 'me'),
      () async {
        for (final (sort, name) in [(2, 'Red'), (1, 'Blue')]) {
          await colours.create(
            GymColourGradesCompanion(
              gymId: Value(cragId),
              sort: Value(sort),
              name: Value(name),
              colourHex: const Value('#000000'),
            ),
            userId: 'me',
          );
        }
      },
    );
    expect(scale.last.map((c) => c.name), ['Blue', 'Red']);
  });

  test(
    'M1-5: only the owner changes a row, and never its key columns',
    () async {
      final cragId = await crag();
      final routeId = await route(cragId);
      final sessionId = await session();
      final ascentId = await ascent(sessionId, routeId);
      await (db.update(db.areas)..where((a) => a.id.equals(cragId))).write(
        const AreasCompanion(visibility: Value('public')),
      );

      await expectLater(
        sessions.softDelete(sessionId, userId: 'someone else'),
        throwsA(isA<NotYourRow>()),
      );
      await expectLater(
        sessions.update(
          sessionId,
          const SessionsCompanion(title: Value('Mine now')),
          userId: 'someone else',
        ),
        throwsA(isA<NotYourRow>()),
      );
      await expectLater(
        areas.update(
          cragId,
          const AreasCompanion(name: Value('Mine now')),
          userId: 'me',
        ),
        throwsA(isA<NotYourRow>()),
        reason: 'public places change through moderated requests',
      );

      void blocked<T extends Table, R>(
        Repository<T, R> repo,
        String id,
        Insertable<R> changes,
      ) => expect(
        () => repo.update(id, changes, userId: 'me'),
        throwsArgumentError,
        reason:
            '${repo.table.actualTableName} '
            '${changes.toColumns(true).keys}',
      );
      blocked(
        sessions,
        sessionId,
        const SessionsCompanion(ownerId: Value('x')),
      );
      blocked(
        sessions,
        sessionId,
        const SessionsCompanion(visibility: Value('public')),
      );
      blocked(
        sessions,
        sessionId,
        const SessionsCompanion(setting: Value('indoor')),
      );
      blocked(
        routes,
        routeId,
        const RoutesCompanion(visibility: Value('public')),
      );
      blocked(routes, routeId, const RoutesCompanion(createdBy: Value('x')));
      blocked(ascents, ascentId, const AscentsCompanion(sessionId: Value('x')));
      blocked(
        ascents,
        ascentId,
        const AscentsCompanion(discipline: Value('trad')),
      );
      blocked(
        ascents,
        ascentId,
        AscentsCompanion(deletedAt: Value(DateTime.utc(2026))),
      );
      expect((await sessions.get(sessionId))!.visibility, 'friends');

      await expectLater(
        ascents.create(
          AscentsCompanion(
            sessionId: Value(sessionId),
            routeId: Value(routeId),
            ordinal: const Value(1),
            ascentType: const Value('lead'),
            style: const Value('flash'),
            tries: const Value(1),
          ),
          userId: 'someone else',
        ),
        throwsA(isA<NotYourRow>()),
      );
      expect(
        () => sessions.setVisibility(sessionId, 'Public', userId: 'me'),
        throwsArgumentError,
      );
    },
  );

  test('M1-5: climbs need a route the user can see', () async {
    final cragId = await crag();
    final sessionId = await session();
    final theirs = await route(cragId, name: 'Their project', user: 'them');
    final deleted = await route(cragId, name: 'Gone');
    await routes.softDelete(deleted, userId: 'me');

    for (final routeId in ['missing', theirs, deleted]) {
      await expectLater(ascent(sessionId, routeId), throwsArgumentError);
    }
    expect(
      () => ascents.create(
        AscentsCompanion(sessionId: Value(sessionId)),
        userId: 'me',
      ),
      throwsArgumentError,
    );
  });

  test(
    'M1-5: a session carries its visibility and deletes to its climbs',
    () async {
      final routeId = await route(await crag());
      final sessionId = await session();
      final ascentId = await ascent(sessionId, routeId);
      final droppedId = await ascent(sessionId, routeId, style: 'repeat');
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
          .setAscentAttribute(droppedId, 'tag', ['tag.pumpy'], userId: 'me');
      await db
          .into(db.ascentBeta)
          .insert(
            AscentBetaCompanion.insert(
              id: 'beta',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              ownerId: 'me',
              ascentId: ascentId,
              betaNotes: 'Heel hook at the third bolt',
            ),
          );

      // Deleting one climb takes its details with it.
      await ascents.softDelete(droppedId, userId: 'me');
      expect(await ascents.get(droppedId), isNull);
      final tag = await db.select(db.ascentAttributes).getSingle();
      expect(tag.deletedAt, isNotNull);

      // Deleted rows still sync, so they follow the visibility too.
      await sessions.setVisibility(sessionId, 'private', userId: 'me');
      expect((await ascents.get(ascentId))!.visibility, 'private');
      expect(
        (await db.select(db.ascentAttributes).getSingle()).visibility,
        'private',
      );

      await sessions.softDelete(sessionId, userId: 'me');
      expect(await ascents.get(ascentId), isNull);
      expect((await db.select(db.ascentBeta).getSingle()).deletedAt, isNotNull);
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
      // A second session on the same day sorts after the first one.
      final sameDay = await session();
      await ascent(sameDay, routeId, style: 'repeat', tries: 1);

      final log = await ascents.routeLog(routeId, userId: 'me');
      expect(log, [
        (style: AscentStyle.attempt, tries: 3),
        (style: AscentStyle.redpoint, tries: 4),
        (style: AscentStyle.repeat, tries: 1),
        (style: AscentStyle.repeat, tries: 1),
      ]);
      expect(checkRouteLog(log), everyElement(isEmpty));
    },
  );

  test("M1-5: search matches names and hides others' private places", () async {
    await crag();
    await crag(name: '100% Bærum');
    await crag(name: 'Ola_Nordmann');
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

    Future<List<String>> names(String term) async => [
      for (final a in await areas.search(term, userId: 'me')) a.name,
    ];
    expect(await names('ols'), ['Kolsås']);
    expect(await names('100%'), ['100% Bærum']);
    expect(await names('a_N'), ['Ola_Nordmann'], reason: '_ counts as a space');
    expect(await names('secret'), isEmpty);
    expect(
      (await routes.find(term: 'nord', userId: 'me')).map((h) => h.route.id),
      [outdoor],
      reason: 'gym routes stay out of the outdoor list',
    );
  });
}
