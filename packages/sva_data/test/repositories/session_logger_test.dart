import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late SessionLogger logger;
  late String crag;
  late String sport;
  late String boulder;
  var tick = 0;
  DateTime clock() => DateTime.utc(2026, 11).add(Duration(seconds: tick++));

  setUp(() async {
    db = SvaDatabase.inMemory();
    logger = SessionLogger(db, clock: clock);
    await GradeRepository(db).seed();
    await AttributeRepository(db).seed();
    final editor = RouteEditor(db, clock: clock);
    crag = await editor.addCrag(
      const NewCrag(name: 'Kolsås', countryCode: 'NO'),
      userId: 'me',
    );
    sport = await editor.addRoute(
      NewRoute(areaId: crag, name: 'Hjemmebane', discipline: 'sport'),
      userId: 'me',
    );
    boulder = await editor.addRoute(
      NewRoute(areaId: crag, name: 'Steinen', discipline: 'boulder'),
      userId: 'me',
    );
  });
  tearDown(() => db.close());

  SessionDraft day(List<ClimbDraft> climbs, {String date = '2026-11-01'}) =>
      SessionDraft(
        localDate: date,
        tz: 'Europe/Oslo',
        visibility: 'friends',
        climbs: climbs,
        title: ' Kveldsøkt ',
        conditions: 'condition.dry',
        partners: ['Kari', '  '],
      );

  ClimbDraft climb(
    String route,
    AscentStyle style, {
    int tries = 1,
    String type = 'lead',
  }) => ClimbDraft(
    routeId: route,
    style: style,
    tries: tries,
    ascentType: type,
    feel: 'feel.hard',
    tags: ['tag.pumpy'],
    qualityStars: 2,
  );

  test('M2-3: a session saves with all its climbs in one step', () async {
    final id = await logger.logOutdoor(
      day([
        climb(sport, AscentStyle.attempt, tries: 2),
        climb(sport, AscentStyle.redpoint, tries: 3),
        climb(boulder, AscentStyle.flash, type: 'boulder'),
      ]),
      userId: 'me',
    );
    final session = (await SessionRepository(db).get(id))!;
    expect(session.title, 'Kveldsøkt');
    expect(session.setting, 'outdoor');
    expect(session.conditions, 'condition.dry');

    final climbs = await AscentRepository(db).watchInSession(id).first;
    expect(climbs.map((a) => (a.ordinal, a.style, a.tries)), [
      (1, 'attempt', 2),
      (2, 'redpoint', 3),
      (3, 'flash', 1),
    ]);
    expect(climbs.every((a) => a.visibility == 'friends'), isTrue);
    expect(climbs.first.feel, 'feel.hard');
    final tags = await AttributeRepository(db)
        .valuesAt(AttributeLevel.ascent, climbs.first.id);
    expect(tags['tag'], ['tag.pumpy']);

    final partners = await db.select(db.sessionMembers).get();
    expect(partners.map((m) => (m.guestName, m.status)), [('Kari', 'guest')]);
    expect(await SessionRepository(db).lastSetting(userId: 'me'), 'outdoor');
  });

  test(
    'M2-3: style and tries follow the M1 rules, in and across sessions',
    () async {
      Future<void> rejected(List<ClimbDraft> climbs, int index) async {
        await expectLater(
          logger.logOutdoor(day(climbs), userId: 'me'),
          throwsA(isA<ClimbRejected>().having((e) => e.index, 'index', index)),
        );
      }

      // A flash after an attempt in the same session.
      await rejected([
        climb(sport, AscentStyle.attempt),
        climb(sport, AscentStyle.flash),
      ], 1);
      // Boulders are flashed, never onsighted.
      await rejected([climb(boulder, AscentStyle.onsight, type: 'boulder')], 0);
      expect(
        await db.select(db.sessions).get(),
        isEmpty,
        reason: 'all or none',
      );

      await logger.logOutdoor(
        day([climb(sport, AscentStyle.attempt, tries: 4)]),
        userId: 'me',
      );
      // The next day the earlier tries count: a redpoint needs at least 5.
      await rejected([climb(sport, AscentStyle.redpoint, tries: 2)], 0);
      await logger.logOutdoor(
        day([climb(sport, AscentStyle.redpoint, tries: 5)], date: '2026-11-02'),
        userId: 'me',
      );
      // After the send, only repeats and attempts.
      await rejected([climb(sport, AscentStyle.redpoint, tries: 6)], 0);
    },
  );

  test('M2-3: bad input is refused', () async {
    final cases = <String, SessionDraft>{
      'no climbs': day(const []),
      'bad date': day([climb(sport, AscentStyle.onsight)], date: '1.11.26'),
      'no such day': day([
        climb(sport, AscentStyle.onsight),
      ], date: '2026-02-30'),
      'in the future': day([
        climb(sport, AscentStyle.onsight),
      ], date: '2027-01-01'),
      'unknown type': day([climb(sport, AscentStyle.onsight, type: 'jetpack')]),
      'unknown route': day([climb('nowhere', AscentStyle.onsight)]),
    };
    for (final MapEntry(key: reason, value: draft) in cases.entries) {
      await expectLater(
        logger.logOutdoor(draft, userId: 'me'),
        throwsArgumentError,
        reason: reason,
      );
    }
    await expectLater(
      logger.logOutdoor(
        day([
          ClimbDraft(
            routeId: sport,
            style: AscentStyle.onsight,
            tries: 1,
            ascentType: 'lead',
            personalGradeId: seedId('grade:font:6A'),
          ),
        ]),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: 'a boulder grade on a route',
    );
    expect(await db.select(db.sessions).get(), isEmpty);
  });

  Future<List<(String, int)>> onRoute(String route) async => [
    for (final e in await AscentRepository(
      db,
    ).routeEntries(route, userId: 'me'))
      (e.ascent.style.name, e.ascent.tries),
  ];

  test('M2-6: removing a climb recalculates later tries', () async {
    final first = await logger.logOutdoor(
      day([
        climb(sport, AscentStyle.attempt, tries: 3),
        climb(boulder, AscentStyle.flash, type: 'boulder'),
      ]),
      userId: 'me',
    );
    await logger.logOutdoor(
      day([climb(sport, AscentStyle.redpoint, tries: 5)], date: '2026-11-02'),
      userId: 'me',
    );
    final attempt = (await AscentRepository(
      db,
    ).watchInSession(first).first).first.id;

    // The redpoint took 2 tries of its own after the 3 on the attempt.
    await logger.editOutdoor(
      first,
      SessionEdit(removed: {attempt}),
      userId: 'me',
    );
    expect(await onRoute(sport), [('redpoint', 2)]);

    // A forgotten attempt added to the first day counts again.
    await logger.editOutdoor(
      first,
      SessionEdit(added: [climb(sport, AscentStyle.attempt, tries: 4)]),
      userId: 'me',
    );
    expect(await onRoute(sport), [('attempt', 4), ('redpoint', 6)]);
  });

  test('M2-6: an edit that breaks a later climb is refused', () async {
    final before = await logger.logOutdoor(
      day([
        climb(boulder, AscentStyle.attempt, type: 'boulder'),
      ], date: '2026-10-31'),
      userId: 'me',
    );
    final first = await logger.logOutdoor(
      day([climb(sport, AscentStyle.flash)]),
      userId: 'me',
    );
    await logger.logOutdoor(
      day([climb(sport, AscentStyle.repeat)], date: '2026-11-02'),
      userId: 'me',
    );
    final flash = (await AscentRepository(
      db,
    ).watchInSession(first).first).single.id;

    // The repeat on the last day needs the flash, even when the whole
    // session goes.
    await expectLater(
      logger.editOutdoor(first, SessionEdit(removed: {flash}), userId: 'me'),
      throwsA(isA<LaterClimbRejected>()),
    );
    // A forgotten attempt the day before would make the flash no flash.
    await expectLater(
      logger.editOutdoor(
        before,
        SessionEdit(added: [climb(sport, AscentStyle.attempt)]),
        userId: 'me',
      ),
      throwsA(isA<LaterClimbRejected>()),
    );
    // An added climb is checked against the session's own climbs.
    await expectLater(
      logger.editOutdoor(
        first,
        SessionEdit(
          added: [
            climb(boulder, AscentStyle.attempt, type: 'boulder'),
            climb(sport, AscentStyle.flash),
          ],
        ),
        userId: 'me',
      ),
      throwsA(isA<ClimbRejected>().having((e) => e.index, 'index', 1)),
    );
    expect(await onRoute(sport), [('flash', 1), ('repeat', 1)]);
    expect(await SessionRepository(db).get(first), isNotNull);
  });

  test('M2-6: removing the last climb deletes the session', () async {
    final id = await logger.logOutdoor(
      day([climb(sport, AscentStyle.flash)]),
      userId: 'me',
    );
    final only = (await AscentRepository(db).watchInSession(id).first).single;

    final deleted = await logger.editOutdoor(
      id,
      SessionEdit(removed: {only.id}),
      userId: 'me',
    );
    expect(deleted, isTrue);
    expect(await SessionRepository(db).get(id), isNull);
    expect(await AscentRepository(db).get(only.id), isNull);
    expect(
      (await db.select(db.sessionMembers).get()).every(
        (m) => m.deletedAt != null,
      ),
      isTrue,
      reason: 'partners go with the session',
    );
  });

  test('M2-6: a climb on a deleted route can still be removed', () async {
    final id = await logger.logOutdoor(
      day([
        climb(sport, AscentStyle.flash),
        climb(boulder, AscentStyle.flash, type: 'boulder'),
      ]),
      userId: 'me',
    );
    await RouteRepository(db).softDelete(sport, userId: 'me');
    final gone = (await AscentRepository(db).watchInSession(id).first).first;

    await logger.editOutdoor(id, SessionEdit(removed: {gone.id}), userId: 'me');
    expect(await AscentRepository(db).get(gone.id), isNull);
  });
}
