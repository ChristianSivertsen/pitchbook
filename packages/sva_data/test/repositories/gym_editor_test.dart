import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late GymEditor gyms;

  setUp(() async {
    db = SvaDatabase.inMemory();
    await AttributeRepository(db).seed();
    gyms = GymEditor(db);
  });
  tearDown(() => db.close());

  const walls = [
    WallDraft(
      name: 'Main wall',
      kind: 'rope',
      heightM: 14,
      angle: 'angle.vertical',
    ),
    WallDraft(name: 'Cave', kind: 'boulder', heightM: 4.5, angle: 'angle.roof'),
  ];

  test('M3-1: a gym and its walls are saved and changed', () async {
    final id = await gyms.addGym(
      const NewGym(
        name: ' Klatreverket ',
        countryCode: 'NO',
        grading: 'colour',
      ),
      walls: walls,
      userId: 'me',
    );
    var setup = (await gyms.setup(id, userId: 'me'))!;
    expect(setup.gym.name, 'Klatreverket');
    expect(setup.gym.type, 'gym');
    expect(setup.gym.visibility, 'private');
    expect(setup.grading, 'colour');
    expect(setup.walls.map((w) => (w.name, w.kind, w.heightM, w.angle)), [
      ('Main wall', 'rope', 14.0, 'angle.vertical'),
      ('Cave', 'boulder', 4.5, 'angle.roof'),
    ]);

    // Rename a wall, drop one, add one, and switch to standard grades.
    final main = setup.walls.first;
    await gyms.updateGym(
      id,
      const NewGym(
        name: 'Klatreverket Oslo',
        countryCode: 'NO',
        grading: 'standard',
      ),
      walls: [
        WallDraft(id: main.id, name: 'Lead wall', kind: 'rope', heightM: 15),
        const WallDraft(
          name: 'Board',
          kind: 'boulder',
          angle: 'angle.overhang',
        ),
      ],
      userId: 'me',
    );
    setup = (await gyms.setup(id, userId: 'me'))!;
    expect(setup.gym.name, 'Klatreverket Oslo');
    expect(setup.grading, 'standard');
    expect(setup.walls.map((w) => (w.id == main.id, w.name, w.heightM)), [
      (true, 'Lead wall', 15.0),
      (false, 'Board', null),
    ]);

    // Someone else can't see or change a private gym.
    expect(await gyms.setup(id, userId: 'someone else'), isNull);
    expect(
      () => gyms.updateGym(
        id,
        const NewGym(name: 'Mine now', countryCode: 'NO', grading: 'none'),
        walls: walls,
        userId: 'someone else',
      ),
      throwsArgumentError,
    );

    // Bad values are refused and nothing is written.
    Future<void> add(NewGym gym, List<WallDraft> walls) =>
        gyms.addGym(gym, walls: walls, userId: 'me');
    const ok = NewGym(name: 'Gym', countryCode: 'NO', grading: 'none');
    expect(
      () => add(
        const NewGym(name: ' ', countryCode: 'NO', grading: 'none'),
        walls,
      ),
      throwsArgumentError,
    );
    expect(
      () => add(
        const NewGym(name: 'Gym', countryCode: 'NO', grading: 'fancy'),
        walls,
      ),
      throwsArgumentError,
    );
    expect(
      () => add(ok, const [WallDraft(name: '', kind: 'rope')]),
      throwsArgumentError,
    );
    expect(
      () => add(ok, const [WallDraft(name: 'W', kind: 'ice')]),
      throwsArgumentError,
    );
    expect(
      () => add(ok, const [WallDraft(name: 'W', kind: 'rope', heightM: 0)]),
      throwsArgumentError,
    );
    expect(
      () => add(ok, const [
        WallDraft(name: 'W', kind: 'rope', angle: 'angle.sideways'),
      ]),
      throwsArgumentError,
    );
    expect(
      await (db.select(db.areas)..where((a) => a.type.equals('gym'))).get(),
      hasLength(1),
    );
  });

  test(
    'M3-1: a new climb on a wall starts with its height and angle',
    () async {
      final id = await gyms.addGym(
        const NewGym(
          name: 'Klatreverket',
          countryCode: 'NO',
          grading: 'colour',
        ),
        walls: walls,
        userId: 'me',
      );
      final [rope, cave] = (await gyms.setup(id, userId: 'me'))!.walls;

      final onRope = await gyms.newGymRoute(rope.id, userId: 'me');
      expect(onRope.areaId.value, id);
      expect(onRope.kind.value, 'gym');
      expect(onRope.gymWallId.value, rope.id);
      expect(onRope.lengthM.value, 14);
      expect(onRope.angle.value, 'angle.vertical');
      expect(onRope.discipline.value, 'sport');

      final onCave = await gyms.newGymRoute(cave.id, userId: 'me');
      expect(onCave.discipline.value, 'boulder');
      expect(onCave.angle.value, 'angle.roof');

      // The angle can be changed for one climb.
      final steeper = onCave.copyWith(angle: const Value('angle.overhang'));
      expect(steeper.angle.value, 'angle.overhang');

      expect(
        () => gyms.newGymRoute(rope.id, userId: 'someone else'),
        throwsArgumentError,
      );
    },
  );
}
