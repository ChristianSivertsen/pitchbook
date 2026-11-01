import 'package:drift/drift.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';

/// Grade systems and their grades as rows, so a local system can be added
/// as data. Like attribute definitions, these are shared rows: the device
/// bootstraps them until the server delivers them through sync (M11-4).
class GradeRepository {
  new(this._db, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final SvaDatabase _db;
  final DateTime Function() _clock;

  /// Adds the built-in systems, or fills in what is missing. Rows that
  /// already exist are left alone: released scores never change, and a row
  /// the server deleted stays deleted.
  Future<void> seed([Iterable<GradeSystem> systems = gradeSystems]) async {
    final now = _clock();
    await _db.batch((batch) {
      var systemSort = 0;
      for (final system in systems) {
        batch.insert(
          _db.gradeSystems,
          GradeSystemsCompanion.insert(
            id: seedId('grade_system:${system.key}'),
            createdAt: now,
            updatedAt: now,
            key: system.key,
            name: system.name,
            gradeType: system.gradeType,
            sort: systemSort++,
            region: Value(system.region),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        for (final (sort, grade) in system.grades.indexed) {
          batch.insert(
            _db.grades,
            GradesCompanion.insert(
              id: seedId('grade:${system.key}:${grade.label}'),
              createdAt: now,
              updatedAt: now,
              systemKey: system.key,
              label: grade.label,
              sort: sort,
              score: Value(grade.score),
              scoreLow: Value(grade.scoreLow),
              scoreHigh: Value(grade.scoreHigh),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  /// Every system in use with its grades, easiest first. A system whose
  /// grades are missing, unscored or out of order, or whose key appears
  /// twice, is skipped rather than half-loaded: wrong grades are worse than
  /// a missing system.
  Future<List<GradeSystem>> systems() async {
    final systemRows =
        await (_db.select(_db.gradeSystems)
              ..where((s) => s.deletedAt.isNull())
              ..orderBy([(s) => OrderingTerm(expression: s.sort)]))
            .get();
    final gradeRows =
        await (_db.select(_db.grades)
              ..where((g) => g.deletedAt.isNull())
              ..orderBy([(g) => OrderingTerm(expression: g.sort)]))
            .get();
    final bySystem = <String, List<GradeRow>>{};
    for (final row in gradeRows) {
      (bySystem[row.systemKey] ??= []).add(row);
    }
    final keyCounts = <String, int>{};
    for (final system in systemRows) {
      keyCounts.update(system.key, (n) => n + 1, ifAbsent: () => 1);
    }
    return [
      for (final system in systemRows)
        if (keyCounts[system.key] == 1)
          if (_grades(bySystem[system.key]) case final grades?)
            GradeSystem(
              key: system.key,
              name: system.name,
              gradeType: system.gradeType,
              region: system.region,
              grades: grades,
            ),
    ];
  }

  static List<Grade>? _grades(List<GradeRow>? rows) {
    if (rows == null || rows.isEmpty) return null;
    final grades = <Grade>[];
    for (final row in rows) {
      final (score, low, high) = (row.score, row.scoreLow, row.scoreHigh);
      if (score == null) return null;
      grades.add(
        low != null && high != null && low != high
            ? Grade.range(row.label, low, high)
            : Grade(row.label, score),
      );
    }
    return isValidGradeList(grades) ? grades : null;
  }
}
