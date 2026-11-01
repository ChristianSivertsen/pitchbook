import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late SvaDatabase db;
  late GearPieceRepository gear;
  late ShoeRepository shoes;
  late BenchmarkDefRepository benchmarks;
  late BenchmarkResultRepository results;
  late ProjectRepository projects;
  late GoalRepository goals;
  var tick = 0;
  DateTime clock() => DateTime.utc(2026, 11).add(Duration(seconds: tick++));

  setUp(() {
    db = SvaDatabase.inMemory();
    gear = GearPieceRepository(db, clock: clock);
    shoes = ShoeRepository(db, clock: clock);
    benchmarks = BenchmarkDefRepository(db, clock: clock);
    results = BenchmarkResultRepository(db, clock: clock);
    projects = ProjectRepository(db, clock: clock);
    goals = GoalRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<String> cam({String label = 'Cam #1'}) => gear.create(
    GearPiecesCompanion(
      category: const Value('cam'),
      label: Value(label),
      madeOn: const Value('2018-06'),
    ),
    userId: 'me',
  );

  Future<String> shoe({String model = 'Solution', String? retired}) =>
      shoes.create(
        ShoesCompanion(
          brand: const Value('La Sportiva'),
          model: Value(model),
          retiredOn: Value(retired),
        ),
        userId: 'me',
      );

  Future<String> standardTest() async {
    await db
        .into(db.benchmarkDefs)
        .insert(
          BenchmarkDefsCompanion.insert(
            id: 'max-hang',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            key: 'max_hang',
            name: 'Max hang',
            unit: 'pct_bw',
            higherIsBetter: true,
          ),
        );
    return 'max-hang';
  }

  Future<String> result(String benchmarkId, String date, double value) =>
      results.create(
        BenchmarkResultsCompanion(
          benchmarkId: Value(benchmarkId),
          performedOn: Value(date),
          value: Value(value),
          visibility: const Value('friends'),
        ),
        userId: 'me',
      );

  Future<String> route({String createdBy = 'me'}) async {
    final id = newId();
    await db
        .into(db.routes)
        .insert(
          RoutesCompanion.insert(
            id: id,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            visibility: 'private',
            createdBy: Value(createdBy),
            areaId: 'crag',
            kind: 'outdoor',
            discipline: 'sport',
            status: 'open',
          ),
        );
    return id;
  }

  Future<String> goal({String? deadline, String status = 'active'}) =>
      goals.create(
        GoalsCompanion(
          kind: const Value('grade'),
          target: const Value('{"metric":"max_score","threshold":27}'),
          deadline: Value(deadline),
          status: Value(status),
          visibility: const Value('friends'),
        ),
        userId: 'me',
      );

  test(
    'M1-5: gear, shoe, training, project and goal repositories create, read, '
    'update, soft-delete and watch',
    () async {
      final benchmarkId = await standardTest();
      final routeId = await route();

      await lifecycle(
        db,
        gear,
        cam,
        const GearPiecesCompanion(label: Value('Cam #1 red')),
        (g) => g.label,
        'Cam #1 red',
      );
      await lifecycle(
        db,
        shoes,
        shoe,
        const ShoesCompanion(sizeLabel: Value('41.5')),
        (s) => s.sizeLabel,
        '41.5',
      );
      await lifecycle(
        db,
        benchmarks,
        () => benchmarks.create(
          const BenchmarkDefsCompanion(
            key: Value('one_arm_hang'),
            name: Value('One-arm hang'),
            unit: Value('s'),
            higherIsBetter: Value(true),
          ),
          userId: 'me',
        ),
        const BenchmarkDefsCompanion(protocol: Value('20 mm, half crimp')),
        (d) => d.protocol,
        '20 mm, half crimp',
      );
      await lifecycle(
        db,
        results,
        () => result(benchmarkId, '2026-10-01', 141),
        const BenchmarkResultsCompanion(value: Value(143)),
        (r) => r.value,
        143,
      );
      await lifecycle(
        db,
        projects,
        () => projects.create(
          ProjectsCompanion(
            routeId: Value(routeId),
            startedOn: const Value('2026-09-12'),
            status: const Value('active'),
          ),
          userId: 'me',
        ),
        const ProjectsCompanion(status: Value('sent')),
        (p) => p.status,
        'sent',
      );
      await lifecycle(
        db,
        goals,
        goal,
        const GoalsCompanion(status: Value('achieved')),
        (g) => g.status,
        'achieved',
      );
    },
  );

  test(
    'M1-5: gear and shoe history keeps dates and deletes with them',
    () async {
      final pieceId = await cam();
      await gear.logEvent(pieceId, 'inspected', '2026-03-01', userId: 'me');
      await gear.logEvent(pieceId, 'reslung', '2026-10-14', userId: 'me');
      expect((await gear.get(pieceId))!.reslungOn, '2026-10');

      final events = await emissions(
        gear.watchEvents(pieceId, userId: 'me'),
        () => gear.logEvent(pieceId, 'fall_held', '2026-10-20', userId: 'me'),
      );
      expect(events.last.map((e) => e.kind), [
        'fall_held',
        'reslung',
        'inspected',
      ]);
      expect(
        () => gear.logEvent(pieceId, 'polished', '2026-10-01', userId: 'me'),
        throwsArgumentError,
      );
      expect(
        () => gear.logEvent(pieceId, 'reslung', '14.10.2026', userId: 'me'),
        throwsArgumentError,
      );
      expect(
        () => gear.update(
          pieceId,
          const GearPiecesCompanion(reslungOn: Value('2030-01')),
          userId: 'me',
        ),
        throwsArgumentError,
        reason: 'resling dates come from events',
      );
      await expectLater(
        gear.logEvent(pieceId, 'lent', '2026-10-01', userId: 'someone else'),
        throwsA(isA<NotYourRow>()),
      );

      await gear.softDelete(pieceId, userId: 'me');
      expect(
        (await db.select(db.gearEvents).get()).every(
          (e) => e.deletedAt != null,
        ),
        isTrue,
      );

      final retired = await shoe(model: 'Anasazi', retired: '2023-02');
      final current = await shoe();
      await shoes.logResole(current, '2025-04-02', userId: 'me');
      final pairs = await shoes.watchMine(userId: 'me').first;
      expect(pairs.map((s) => s.id), [
        current,
        retired,
      ], reason: 'in use first');
      expect(
        (await shoes.watchResoles(current, userId: 'me').first).single.date,
        '2025-04-02',
      );
      await shoes.softDelete(current, userId: 'me');
      expect(
        (await db.select(db.shoeResoles).getSingle()).deletedAt,
        isNotNull,
      );
    },
  );

  test('M1-5: standard tests are read-only and results need a test', () async {
    final standard = await standardTest();
    final mine = await benchmarks.create(
      const BenchmarkDefsCompanion(
        key: Value('pancake'),
        name: Value('Pancake'),
        unit: Value('cm'),
        higherIsBetter: Value(false),
      ),
      userId: 'me',
    );
    await benchmarks.create(
      const BenchmarkDefsCompanion(
        key: Value('secret'),
        name: Value('Their test'),
        unit: Value('s'),
        higherIsBetter: Value(true),
      ),
      userId: 'someone else',
    );

    final available = await benchmarks.watchAvailable(userId: 'me').first;
    expect(available.map((d) => d.id), [standard, mine]);
    await expectLater(
      benchmarks.update(
        standard,
        const BenchmarkDefsCompanion(name: Value('Mine now')),
        userId: 'me',
      ),
      throwsA(isA<NotYourRow>()),
    );

    await result(standard, '2026-10-01', 141);
    await result(standard, '2025-11-10', 118);
    final history = await results.watchFor(standard, userId: 'me').first;
    expect(history.map((r) => r.value), [118, 141], reason: 'oldest first');
    await expectLater(result('missing', '2026-10-01', 1), throwsArgumentError);
    expect(() => result(standard, 'yesterday', 1), throwsArgumentError);

    await results.setVisibility(history.first.id, 'private', userId: 'me');
    expect((await results.get(history.first.id))!.visibility, 'private');
    expect(
      () => results.update(
        history.first.id,
        const BenchmarkResultsCompanion(visibility: Value('public')),
        userId: 'me',
      ),
      throwsArgumentError,
    );
  });

  test('M1-5: projects and goals list by status in a useful order', () async {
    final routeId = await route();
    final theirs = await route(createdBy: 'someone else');
    final active = await projects.create(
      ProjectsCompanion(
        routeId: Value(routeId),
        startedOn: const Value('2026-09-12'),
        status: const Value('active'),
      ),
      userId: 'me',
    );
    await expectLater(
      projects.create(
        ProjectsCompanion(
          routeId: Value(theirs),
          startedOn: const Value('2026-09-12'),
          status: const Value('active'),
        ),
        userId: 'me',
      ),
      throwsArgumentError,
      reason: "someone else's private route",
    );
    expect(
      (await projects.watchMine(userId: 'me', status: 'active').first)
          .single
          .id,
      active,
    );
    expect(
      await projects.watchMine(userId: 'me', status: 'sent').first,
      isEmpty,
    );

    final later = await goal(deadline: '2027-06-01');
    final open = await goal();
    final soon = await goal(deadline: '2026-12-31');
    await goal(status: 'achieved');
    final list = await goals.watchMine(userId: 'me', status: 'active').first;
    expect(list.map((g) => g.id), [soon, later, open]);
    expect(
      () => goals.setVisibility(soon, 'everyone', userId: 'me'),
      throwsArgumentError,
    );
  });

  test('M1-5: values are checked and links stay with the owner', () async {
    expect(
      () => gear.create(
        const GearPiecesCompanion(
          category: Value('cam'),
          label: Value('Cam'),
          madeOn: Value('2018-13'),
        ),
        userId: 'me',
      ),
      throwsArgumentError,
    );
    final pieceId = await cam();
    expect(
      () => gear.update(
        pieceId,
        const GearPiecesCompanion(category: Value('spaceship')),
        userId: 'me',
      ),
      throwsArgumentError,
    );
    expect(
      () => gear.logEvent(pieceId, 'inspected', '2026-02-31', userId: 'me'),
      throwsArgumentError,
      reason: 'no 31 February',
    );
    await gear.logEvent(pieceId, 'reslung', '2026-10-14', userId: 'me');
    await gear.logEvent(pieceId, 'reslung', '2021-01-10', userId: 'me');
    expect((await gear.get(pieceId))!.reslungOn, '2026-10', reason: 'latest');

    final standard = await standardTest();
    expect(
      () => result(standard, '2026-10-01', double.nan),
      throwsArgumentError,
    );
    final own = await benchmarks.create(
      const BenchmarkDefsCompanion(
        key: Value('lock_off'),
        name: Value('Lock-off'),
        unit: Value('s'),
        higherIsBetter: Value(true),
      ),
      userId: 'me',
    );
    final resultId = await result(own, '2026-10-01', 9);
    await benchmarks.softDelete(own, userId: 'me');
    expect(await results.get(resultId), isNull, reason: 'results go too');

    final routeId = await route();
    final projectId = await projects.create(
      ProjectsCompanion(
        routeId: Value(routeId),
        startedOn: const Value('2026-09-12'),
        status: const Value('active'),
      ),
      userId: 'me',
    );
    expect(
      () => projects.update(
        projectId,
        const ProjectsCompanion(sentAscentId: Value('theirs')),
        userId: 'me',
      ),
      throwsArgumentError,
    );
    expect(
      () => projects.update(
        projectId,
        const ProjectsCompanion(status: Value('crushed')),
        userId: 'me',
      ),
      throwsArgumentError,
    );
    await expectLater(
      projects.markSent(projectId, 'missing', userId: 'me'),
      throwsArgumentError,
    );
    await db
        .into(db.ascents)
        .insert(
          AscentsCompanion.insert(
            id: 'send',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            ownerId: 'me',
            visibility: 'friends',
            sessionId: 'session',
            routeId: routeId,
            ordinal: 1,
            ascentType: 'lead',
            style: 'redpoint',
            tries: 5,
            setting: 'outdoor',
            discipline: 'sport',
          ),
        );
    await projects.markSent(projectId, 'send', userId: 'me');
    final sent = (await projects.get(projectId))!;
    expect((sent.status, sent.sentAscentId), ('sent', 'send'));
  });
}
