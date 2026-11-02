import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late RouteEditor editor;

  setUp(() async {
    db = SvaDatabase.inMemory();
    editor = RouteEditor(db);
    await GradeRepository(db).seed();
    await AttributeRepository(db).seed();
  });
  tearDown(() => db.close());

  Future<String> kolsas() => editor.addCrag(
    const NewCrag(
      name: '  Kolsås ',
      countryCode: 'NO',
      rockType: 'rock.basalt',
      location: (lat: 59.92, lon: 10.50),
    ),
    userId: 'me',
  );

  test('M2-2: a new route appears in search immediately', () async {
    final crag = await kolsas();
    final seen = <List<String?>>[];
    final subscription = RouteRepository(db)
        .watchFind(term: 'hjemme', userId: 'me')
        .listen((hits) => seen.add([for (final h in hits) h.route.name]));
    await pumpEventQueue();
    await editor.addRoute(
      NewRoute(areaId: crag, name: 'Hjemmebane', discipline: 'sport'),
      userId: 'me',
    );
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen.first, isEmpty);
    expect(seen.last, ['Hjemmebane']);
  });

  test('M2-2: rock type is inherited from the crag', () async {
    final crag = await kolsas();
    final route = await editor.addRoute(
      NewRoute(areaId: crag, name: 'Hjemmebane', discipline: 'sport'),
      userId: 'me',
    );
    final details = await AttributeRepository(db)
        .resolvedForRoute(route, userId: 'me');
    expect(details['rock_type'], ['rock.basalt']);
  });

  test('M2-2: a route saves its grade, details and pitches', () async {
    final crag = await kolsas();
    final id = await editor.addRoute(
      NewRoute(
        areaId: crag,
        name: 'Nordveggen direkte',
        discipline: 'trad',
        gradeId: seedId('grade:nor:6'),
        lengthM: 120,
        pitches: [
          NewPitch(gradeId: seedId('grade:nor:5'), lengthM: 40),
          NewPitch(gradeId: seedId('grade:nor:6'), lengthM: 45),
          const NewPitch(lengthM: 35),
        ],
        angle: 'angle.vertical',
        features: ['feature.corner', 'feature.hand_crack'],
        holds: ['hold.jug'],
        protection: 'protection.trad',
        descent: 'descent.rappel',
        ropeLengthM: 60,
        firstAscent: ' Ola Nordmann, 1978 ',
      ),
      userId: 'me',
    );

    final route = (await RouteRepository(db).get(id))!;
    expect(route.name, 'Nordveggen direkte');
    expect(route.visibility, 'private', reason: 'waits for a moderator');
    expect(route.createdBy, 'me');
    expect(route.pitchCount, 3);
    expect(route.firstAscent, 'Ola Nordmann, 1978');
    expect((await RouteRepository(db).hit(id, userId: 'me'))?.grade, '6');

    final pitches = await (db.select(
      db.pitches,
    )..where((p) => p.routeId.equals(id))).get();
    expect(pitches.map((p) => (p.number, p.lengthM)), [
      (1, 40),
      (2, 45),
      (3, 35),
    ]);
    final pitchGrades = await (db.select(
      db.routeGrades,
    )..where((g) => g.pitchId.isNotNull())).get();
    expect(pitchGrades.map((g) => g.gradeId).toSet(), {
      seedId('grade:nor:5'),
      seedId('grade:nor:6'),
    });

    final details = await AttributeRepository(db)
        .resolvedForRoute(id, userId: 'me');
    expect(details['feature'], ['feature.corner', 'feature.hand_crack']);
    expect(details['hold'], ['hold.jug']);
    expect(details['protection'], ['protection.trad']);
    expect(details['rope_length_m'], ['60']);
  });

  test('M2-2: bad input is refused and nothing is written', () async {
    final crag = await kolsas();
    final cases = <String, NewRoute>{
      'empty name': NewRoute(areaId: crag, name: '  ', discipline: 'sport'),
      'unknown discipline': NewRoute(
        areaId: crag,
        name: 'X',
        discipline: 'yoga',
      ),
      'unknown hold': NewRoute(
        areaId: crag,
        name: 'X',
        discipline: 'sport',
        holds: ['hold.banana'],
      ),
      'boulder grade on a route': NewRoute(
        areaId: crag,
        name: 'X',
        discipline: 'sport',
        gradeId: seedId('grade:font:6A'),
      ),
      'negative length': NewRoute(
        areaId: crag,
        name: 'X',
        discipline: 'sport',
        lengthM: -5,
      ),
      'missing place': const NewRoute(
        areaId: 'nowhere',
        name: 'X',
        discipline: 'sport',
      ),
    };
    for (final MapEntry(key: reason, value: route) in cases.entries) {
      await expectLater(
        editor.addRoute(route, userId: 'me'),
        throwsArgumentError,
        reason: reason,
      );
    }
    final someoneElses = await editor.addCrag(
      const NewCrag(name: 'Hemmelig', countryCode: 'NO'),
      userId: 'them',
    );
    await expectLater(
      editor.addRoute(
        NewRoute(areaId: someoneElses, name: 'X', discipline: 'sport'),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: "someone else's private crag",
    );
    final region = await AreaRepository(db).createPrivate(
      const AreasCompanion(
        type: Value('region'),
        name: Value('Viken'),
        countryCode: Value('NO'),
      ),
      userId: 'me',
    );
    await expectLater(
      editor.addRoute(
        NewRoute(areaId: region, name: 'X', discipline: 'sport'),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: 'routes go in a crag or sector, not a region',
    );
    await expectLater(
      editor.addCrag(
        NewCrag(name: 'X', countryCode: 'NO', parentId: crag),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: 'a crag does not go inside a crag',
    );
    for (final crag in [
      const NewCrag(name: 'X', countryCode: 'norway'),
      const NewCrag(name: 'X', countryCode: 'NO', location: (lat: 91, lon: 0)),
      const NewCrag(name: 'X', countryCode: 'NO', rockType: 'rock.cheese'),
    ]) {
      await expectLater(
        editor.addCrag(crag, userId: 'me'),
        throwsArgumentError,
      );
    }
    expect(await db.select(db.routes).get(), isEmpty);
    expect(await db.select(db.areas).get(), hasLength(3));
  });

  test('M2-2: the route form lists crags and sectors you can see', () async {
    final crag = await kolsas();
    await AreaRepository(db).createPrivate(
      AreasCompanion(
        type: const Value('sector'),
        name: const Value('Ankerveggen'),
        parentId: Value(crag),
        countryCode: const Value('NO'),
      ),
      userId: 'me',
    );
    await editor.addCrag(
      const NewCrag(name: 'Hemmelig', countryCode: 'NO'),
      userId: 'them',
    );
    final places = await AreaRepository(db)
        .watchOfTypes({'crag', 'sector'}, userId: 'me')
        .first;
    expect(places.map((a) => a.name), ['Ankerveggen', 'Kolsås']);
  });
}
