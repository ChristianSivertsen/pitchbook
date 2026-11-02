import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late AreaRepository areas;
  late RouteRepository routes;
  late SessionRepository sessions;
  late AscentRepository ascents;

  setUp(() {
    db = SvaDatabase.inMemory();
    areas = AreaRepository(db);
    routes = RouteRepository(db);
    sessions = SessionRepository(db);
    ascents = AscentRepository(db);
  });
  tearDown(() => db.close());

  Future<String> place(
    String name, {
    String type = 'crag',
    String? parent,
    LatLon? at,
  }) => areas.createPrivate(
    AreasCompanion(
      type: Value(type),
      name: Value(name),
      parentId: Value(parent),
      countryCode: const Value('NO'),
      latitude: Value(at?.lat),
      longitude: Value(at?.lon),
    ),
    userId: 'me',
  );

  Future<String> route(String areaId, String name) => routes.createPrivate(
    RoutesCompanion(
      areaId: Value(areaId),
      kind: const Value('outdoor'),
      name: Value(name),
      discipline: const Value('sport'),
      status: const Value('open'),
    ),
    userId: 'me',
  );

  Future<void> climb(String routeId, String date) async {
    final session = await sessions.create(
      SessionsCompanion(
        setting: const Value('outdoor'),
        localDate: Value(date),
        tz: const Value('Europe/Oslo'),
        visibility: const Value('private'),
      ),
      userId: 'me',
    );
    await ascents.create(
      AscentsCompanion(
        sessionId: Value(session),
        routeId: Value(routeId),
        ordinal: const Value(1),
        ascentType: const Value('lead'),
        style: const Value('attempt'),
        tries: const Value(1),
      ),
      userId: 'me',
    );
  }

  Future<List<String?>> names({String term = '', LatLon? near}) async => [
    for (final hit in await routes.find(term: term, userId: 'me', near: near))
      hit.route.name,
  ];

  const oslo = (lat: 59.91, lon: 10.75);

  test(
    'M2-1: search lists recent routes, then nearby, then by name match',
    () async {
      final kolsas = await place('Kolsås', at: (lat: 59.92, lon: 10.50));
      final flatanger = await place('Flatanger', at: (lat: 64.49, lon: 10.80));
      final sector = await place(
        'Hanshelleren',
        type: 'sector',
        parent: flatanger,
      );
      await route(sector, 'Silence');
      final old = await route(sector, 'Odins Øye');
      final recent = await route(sector, 'Nordic Plate');
      await route(kolsas, 'Øyas sti');
      await route(kolsas, 'Bøyen');
      await route(kolsas, 'Sti for øye');
      await climb(old, '2025-06-01');
      await climb(recent, '2026-10-30');

      expect(await names(near: oslo), [
        'Nordic Plate', // climbed most recently
        'Odins Øye', // climbed before
        'Bøyen', // Kolsås is near Oslo, so its routes come next, by name
        'Sti for øye',
        'Øyas sti',
        'Silence', // Flatanger is far away
      ]);
      expect(await names(term: 'øy', near: oslo), [
        'Odins Øye',
        'Sti for øye', // a word starts with the term; s comes before ø
        'Øyas sti',
        'Bøyen', // the term is inside a word
      ]);
      // A place's name finds the routes in it.
      expect(await names(term: 'flatang'), [
        'Nordic Plate',
        'Odins Øye',
        'Silence',
      ]);
      final hit = (await routes.find(
        term: 'silence',
        userId: 'me',
        near: oslo,
      )).single;
      expect(hit.crag, 'Flatanger', reason: 'the crag above the sector');
      expect(hit.distanceKm, closeTo(509, 5));
      expect(hit.lastClimbed, isNull);
    },
  );

  test('M2-1: æ, ø and å match as Norwegians expect', () async {
    final crag = await place('Fløyen');
    await route(crag, 'Ærlig talt');
    await route(crag, 'Smått og godt');
    await route(crag, 'Aasmund');
    await route(crag, 'Store Smatt');

    expect(await names(term: 'FLØ'), hasLength(4), reason: 'any case');
    expect(await names(term: 'floyen'), hasLength(4), reason: 'without ø');
    expect(await names(term: 'ÆRLIG'), ['Ærlig talt']);
    expect(await names(term: 'aerlig'), ['Ærlig talt']);
    expect(await names(term: 'smått'), ['Smått og godt']);
    expect(await names(term: 'smatt'), [
      'Smått og godt',
      'Store Smatt',
    ], reason: 'typed without å, both match');
    expect(await names(term: 'åsm'), ['Aasmund'], reason: 'aa is å');
    expect(await names(term: ' - '), isEmpty, reason: 'punctuation only');
    await route(crag, 'Καλύμνος');
    expect(await names(term: 'ΚΑΛΎ'), ['Καλύμνος'], reason: 'other scripts');

    final id = await route(crag, 'Gammelt navn');
    await routes.update(
      id,
      const RoutesCompanion(name: Value('Nytt søkk')),
      userId: 'me',
    );
    expect(await names(term: 'søkk'), ['Nytt søkk'], reason: 'renames count');
    expect(await names(term: 'gammelt'), isEmpty);
    expect(
      () => routes.update(
        id,
        const RoutesCompanion(searchKey: Value('x')),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: 'keys follow the name',
    );
  });

  test('M2-1: search returns results as you type on 1 000 routes', () async {
    final crag = await place('Kolsås', at: (lat: 59.92, lon: 10.50));
    await db.batch((b) {
      for (var i = 0; i < 1000; i++) {
        b.insert(
          db.routes,
          RoutesCompanion.insert(
            id: 'r$i',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            visibility: 'public',
            areaId: crag,
            kind: 'outdoor',
            name: Value('Rute $i Øst'),
            discipline: 'sport',
            status: 'open',
          ),
        );
      }
    });
    await db.fillNameKeys();
    await climb('r500', '2026-10-01');

    // Warm up, then time each keystroke of a typed search.
    await routes.find(userId: 'me', near: oslo);
    final watch = Stopwatch()..start();
    for (final term in ['', 'r', 'ru', 'rut', 'rute', 'rute 5', 'rute 50']) {
      final hits = await routes.find(term: term, userId: 'me', near: oslo);
      expect(hits.first.route.id, 'r500', reason: 'the climbed route first');
    }
    // Seven searches; a frame at 60 Hz is about 16 ms each. The bound is
    // loose so slow CI machines pass, while a full scan per keystroke of
    // a much larger table would not.
    expect(watch.elapsedMilliseconds, lessThan(7 * 50));
  });

  test('M2-1: nearby starts from where you last climbed outdoors', () async {
    expect(await sessions.lastOutdoorLocation(userId: 'me'), isNull);
    final crag = await place('Flatanger', at: (lat: 64.49, lon: 10.80));
    final sector = await place('Hanshelleren', type: 'sector', parent: crag);
    final far = await place('Kalymnos', at: (lat: 36.98, lon: 26.98));
    await climb(await route(far, 'DNA'), '2026-05-01');
    await climb(await route(sector, 'Silence'), '2026-10-01');
    expect(await sessions.lastOutdoorLocation(userId: 'me'), (
      lat: 64.49,
      lon: 10.80,
    ), reason: "the latest session's route, from the crag above its sector");
  });

  test(
    'M2-1: a route shows its grade, inherited details and your climbs',
    () async {
      await GradeRepository(db).seed();
      final crag = await place('Kolsås');
      await db.customStatement(
        "UPDATE areas SET rock_type = 'rock.basalt' WHERE id = ?",
        [crag],
      );
      final id = await route(crag, 'Hjemmebane');
      await db
          .into(db.routeGrades)
          .insert(
            RouteGradesCompanion.insert(
              id: 'g1',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              routeId: id,
              gradeType: 'free_route',
              gradeId: seedId('grade:nor:7-'),
              source: 'official',
            ),
          );
      await climb(id, '2026-05-01');
      await climb(id, '2026-10-30');

      final hit = await routes.hit(id, userId: 'me');
      expect(hit?.grade, '7-');
      expect(hit?.crag, 'Kolsås');
      expect(hit?.lastClimbed, '2026-10-30');
      expect(await routes.hit(id, userId: 'someone else'), isNull);

      final details = await AttributeRepository(db)
          .resolvedForRoute(id, userId: 'me');
      expect(
        await AttributeRepository(db).resolvedForRoute(id, userId: 'them'),
        isEmpty,
      );
      expect(details['rock_type'], ['rock.basalt'], reason: 'from the crag');
      expect(details['discipline'], ['sport']);

      final history = await ascents.watchOnRoute(id, userId: 'me').first;
      expect(history.map((h) => h.date), ['2026-10-30', '2026-05-01']);
    },
  );

  test('M2-1: live search updates when a route is added', () async {
    final crag = await place('Kolsås');
    final seen = <List<String?>>[];
    final subscription = routes
        .watchFind(term: 'kol', userId: 'me')
        .listen((hits) => seen.add([for (final h in hits) h.route.name]));
    await pumpEventQueue();
    await route(crag, 'Hjemmebane');
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen.first, isEmpty);
    expect(seen.last, ['Hjemmebane']);
  });
}
