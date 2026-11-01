import 'package:drift/native.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late GradeRepository repo;
  final now = DateTime.utc(2026, 11);

  setUp(() {
    db = SvaDatabase(NativeDatabase.memory());
    repo = GradeRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('M1-3: grade systems load from the database as data', () async {
    await repo.seed();
    await repo.seed(); // seeding again adds nothing

    final loaded = await repo.systems();
    expect(loaded.map((s) => s.key), gradeSystems.map((s) => s.key));
    for (final (i, system) in loaded.indexed) {
      final original = gradeSystems[i];
      expect(system.grades.map((g) => g.label), [
        for (final g in original.grades) g.label,
      ]);
      expect(system.grades.map((g) => (g.scoreLow, g.scoreHigh)), [
        for (final g in original.grades) (g.scoreLow, g.scoreHigh),
      ]);
    }
    expect(
      await db.select(db.grades).get(),
      hasLength(gradeSystems.fold<int>(0, (n, s) => n + s.grades.length)),
    );

    // A local system added as data converts like the built-in ones.
    await db
        .into(db.gradeSystems)
        .insert(
          GradeSystemsCompanion.insert(
            id: 'saxon',
            createdAt: now,
            updatedAt: now,
            key: 'saxon',
            name: 'Saxon',
            gradeType: 'free_route',
            sort: 99,
          ),
        );
    for (final (sort, label, score) in [(0, 'VIIa', 18.0), (1, 'VIIb', 19.0)]) {
      await db
          .into(db.grades)
          .insert(
            GradesCompanion.insert(
              id: 'saxon-$label',
              createdAt: now,
              updatedAt: now,
              systemKey: 'saxon',
              label: label,
              sort: sort,
              score: Value(score),
            ),
          );
    }
    final saxon = (await repo.systems()).singleWhere((s) => s.key == 'saxon');
    expect(convertGrade('VIIb', saxon, french)?.label, '6c');
  });

  test('M1-3: malformed grade systems from the database are skipped', () async {
    await repo.seed();
    Future<void> system(String id, String key) => db
        .into(db.gradeSystems)
        .insert(
          GradeSystemsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            key: key,
            name: key,
            gradeType: 'free_route',
            sort: 99,
          ),
        );
    Future<void> grade(String system, int sort, String label, double? score) =>
        db
            .into(db.grades)
            .insert(
              GradesCompanion.insert(
                id: '$system-$sort',
                createdAt: now,
                updatedAt: now,
                systemKey: system,
                label: label,
                sort: sort,
                score: Value(score),
              ),
            );

    await system('backwards', 'backwards');
    await grade('backwards', 0, 'hard', 20);
    await grade('backwards', 1, 'easy', 10);
    await system('unscored', 'unscored');
    await grade('unscored', 0, 'a', null);
    // A second row for a built-in key, as a bad sync could deliver.
    await system('twin', 'nor');

    final keys = (await repo.systems()).map((s) => s.key);
    expect(keys, isNot(contains('backwards')));
    expect(keys, isNot(contains('unscored')));
    expect(keys, isNot(contains('nor')), reason: 'ambiguous, so skipped');
    expect(keys, containsAll(['french', 'font']));
  });
}
