import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/repositories/repository.dart';

/// A `YYYY-MM-DD` day or, for month columns, a `YYYY-MM` month.
final _date = RegExp(r'^\d{4}-(0[1-9]|1[0-2])(-(0[1-9]|[12]\d|3[01]))?$');

void _checkDate(String value, {bool monthOnly = false}) {
  var ok = _date.hasMatch(value) && value.length == (monthOnly ? 7 : 10);
  if (ok && value.length == 10) {
    // Reject days that do not exist, such as 2026-02-31.
    final parsed = DateTime.parse('${value}T00:00:00Z');
    ok = parsed.toIso8601String().startsWith(value);
  }
  if (!ok) throw ArgumentError.value(value, 'date');
}

/// Checks the date and month columns present in [columns]: an invalid
/// value throws [ArgumentError] before anything is written.
void _checkDates(
  Map<String, Expression<Object>> columns, {
  Set<String> days = const {},
  Set<String> months = const {},
}) {
  for (final MapEntry(:key, :value) in columns.entries) {
    if (!days.contains(key) && !months.contains(key)) continue;
    if (value is! Variable<Object>) continue;
    final text = value.value;
    if (text == null) continue;
    if (text is! String) throw ArgumentError.value(text, key);
    _checkDate(text, monthOnly: months.contains(key));
  }
}

/// Throws [ArgumentError] unless [value] (when present) is in [allowed].
void _checkOneOf(String name, Object? value, Set<String> allowed) {
  if (value != null && !allowed.contains(value)) {
    throw ArgumentError.value(value, name);
  }
}

String? _text(Map<String, Expression<Object>> columns, String key) {
  final value = columns[key];
  return value is Variable<Object> ? value.value as String? : null;
}

/// Each physical piece of gear a user owns, with its history.
class GearPieceRepository extends Repository<$GearPiecesTable, GearPiece> {
  new(super.db, {super.clock});

  @override
  $GearPiecesTable get table => db.gearPieces;
  @override
  RowAccess get access => RowAccess.owned;

  /// Reslinging and retiring are events, so the dates change with them.
  @override
  Set<String> get protectedColumns => {
    ...super.protectedColumns,
    'reslung_on',
    'retired_on',
  };

  static const _months = {'made_on', 'bought_on'};
  static const categories = {
    'cam',
    'nut',
    'hex',
    'tricam',
    'sling',
    'alpine_draw',
    'quickdraw',
    'carabiner',
    'locker',
    'belay_device',
    'nut_tool',
    'rope',
    'harness',
    'helmet',
    'ice_screw',
    'ice_tool',
    'crampons',
    'aider',
    'hook',
    'cam_hook',
    'daisy',
  };

  void _validate(Map<String, Expression<Object>> columns) {
    _checkDates(columns, months: _months);
    _checkOneOf('category', _text(columns, 'category'), categories);
  }

  @override
  Future<void> update(
    String id,
    Insertable<GearPiece> changes, {
    required String userId,
  }) {
    _validate(changes.toColumns(true));
    return super.update(id, changes, userId: userId);
  }

  /// Adds a piece for [userId]. Returns the new id.
  Future<String> create(
    GearPiecesCompanion draft, {
    required String userId,
  }) async {
    _validate(draft.toColumns(true));
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
        ownerId: Value(userId),
        reslungOn: const Value(null),
        retiredOn: const Value(null),
      ),
    );
    return id;
  }

  /// [userId]'s pieces by category and label, retired ones included (the
  /// rack shows them greyed out).
  Stream<List<GearPiece>> watchMine({required String userId}) {
    final query = live()
      ..where((g) => g.ownerId.equals(userId))
      ..orderBy([
        (g) => OrderingTerm(expression: g.category),
        (g) => OrderingTerm(expression: g.label),
      ]);
    return query.watch();
  }

  /// Logs what happened to a piece on [date] (`YYYY-MM-DD`). A resling or
  /// retirement also updates the piece's own month, for reminders.
  Future<String> logEvent(
    String pieceId,
    String kind,
    String date, {
    required String userId,
    String? notes,
  }) {
    const kinds = {'reslung', 'inspected', 'fall_held', 'lent', 'retired'};
    if (!kinds.contains(kind)) throw ArgumentError.value(kind, 'kind');
    _checkDate(date);
    return db.transaction(() async {
      final month = date.substring(0, 7);
      await checkWritable(pieceId, userId);
      final piece = (await get(pieceId))!;
      // An older event logged late never moves the month backwards.
      bool later(String? current) =>
          current == null || month.compareTo(current) > 0;
      await writeChecked(pieceId, userId, {
        if (kind == 'reslung' && later(piece.reslungOn))
          'reslung_on': Variable(month),
        if (kind == 'retired' && later(piece.retiredOn))
          'retired_on': Variable(month),
      });
      final id = newId();
      final now = clock();
      await db
          .into(db.gearEvents)
          .insert(
            GearEventsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              ownerId: userId,
              pieceId: pieceId,
              kind: kind,
              date: date,
              notes: Value(notes),
            ),
          );
      return id;
    });
  }

  /// A piece's history, newest first.
  Stream<List<GearEvent>> watchEvents(
    String pieceId, {
    required String userId,
  }) {
    final query = db.select(db.gearEvents)
      ..where(
        (e) =>
            e.pieceId.equals(pieceId) &
            e.ownerId.equals(userId) &
            e.deletedAt.isNull(),
      )
      ..orderBy([(e) => OrderingTerm.desc(e.date)]);
    return query.watch();
  }

  /// Soft-deletes a piece with its history.
  @override
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        await markDeleted(table, table.id, [id]);
        await markDeleted(db.gearEvents, db.gearEvents.pieceId, [id]);
      });
}

/// Climbing shoes and their resoles.
class ShoeRepository extends Repository<$ShoesTable, Shoe> {
  new(super.db, {super.clock});

  @override
  $ShoesTable get table => db.shoes;
  @override
  RowAccess get access => RowAccess.owned;

  void _validate(Map<String, Expression<Object>> columns) {
    _checkDates(columns, months: {'bought_on', 'retired_on'});
    _checkOneOf('closure', _text(columns, 'closure'), {
      'velcro',
      'lace',
      'slipper',
    });
  }

  @override
  Future<void> update(
    String id,
    Insertable<Shoe> changes, {
    required String userId,
  }) {
    _validate(changes.toColumns(true));
    return super.update(id, changes, userId: userId);
  }

  /// Adds shoes for [userId]. Returns the new id.
  Future<String> create(ShoesCompanion draft, {required String userId}) async {
    _validate(draft.toColumns(true));
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
        ownerId: Value(userId),
      ),
    );
    return id;
  }

  /// [userId]'s shoes, in use first, then by brand and model.
  Stream<List<Shoe>> watchMine({required String userId}) {
    final query = live()
      ..where((s) => s.ownerId.equals(userId))
      ..orderBy([
        (s) => OrderingTerm(expression: s.retiredOn.isNotNull()),
        (s) => OrderingTerm(expression: s.brand),
        (s) => OrderingTerm(expression: s.model),
      ]);
    return query.watch();
  }

  /// Logs a resole on [date] (`YYYY-MM-DD`). Returns the new id.
  Future<String> logResole(
    String shoeId,
    String date, {
    required String userId,
    String? notes,
  }) {
    _checkDate(date);
    return db.transaction(() async {
      await checkWritable(shoeId, userId);
      final id = newId();
      final now = clock();
      await db
          .into(db.shoeResoles)
          .insert(
            ShoeResolesCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              ownerId: userId,
              shoeId: shoeId,
              date: date,
              notes: Value(notes),
            ),
          );
      return id;
    });
  }

  /// A pair's resoles, newest first.
  Stream<List<ShoeResole>> watchResoles(
    String shoeId, {
    required String userId,
  }) {
    final query = db.select(db.shoeResoles)
      ..where(
        (r) =>
            r.shoeId.equals(shoeId) &
            r.ownerId.equals(userId) &
            r.deletedAt.isNull(),
      )
      ..orderBy([(r) => OrderingTerm.desc(r.date)]);
    return query.watch();
  }

  /// Soft-deletes shoes with their resoles.
  @override
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        await markDeleted(table, table.id, [id]);
        await markDeleted(db.shoeResoles, db.shoeResoles.shoeId, [id]);
      });
}

/// Strength and mobility tests: the standard ones and the user's own.
class BenchmarkDefRepository
    extends Repository<$BenchmarkDefsTable, BenchmarkDef> {
  new(super.db, {super.clock});

  @override
  $BenchmarkDefsTable get table => db.benchmarkDefs;

  /// Standard tests have no owner, so nobody can change them.
  @override
  RowAccess get access => RowAccess.owned;

  /// Adds a test of [userId]'s own. Returns the new id.
  Future<String> create(
    BenchmarkDefsCompanion draft, {
    required String userId,
  }) async {
    _checkOneOf('unit', draft.unit.value, {
      'pct_bw',
      'kg',
      's',
      'reps',
      'cm',
      'deg',
    });
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
        ownerId: Value(userId),
      ),
    );
    return id;
  }

  /// Soft-deletes one of [userId]'s own tests with its results.
  @override
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        await markDeleted(table, table.id, [id]);
        await markDeleted(
          db.benchmarkResults,
          db.benchmarkResults.benchmarkId,
          [id],
        );
      });

  /// The standard tests and [userId]'s own, by name.
  Stream<List<BenchmarkDef>> watchAvailable({required String userId}) {
    final query = live()
      ..where((d) => d.ownerId.isNull() | d.ownerId.equals(userId))
      ..orderBy([(d) => OrderingTerm(expression: d.name)]);
    return query.watch();
  }
}

/// Results of strength and mobility tests.
class BenchmarkResultRepository
    extends Repository<$BenchmarkResultsTable, BenchmarkResult>
    with ChangeVisibility<$BenchmarkResultsTable, BenchmarkResult> {
  new(super.db, {super.clock});

  @override
  $BenchmarkResultsTable get table => db.benchmarkResults;
  @override
  RowAccess get access => RowAccess.owned;

  /// A result belongs to one test.
  @override
  Set<String> get protectedColumns => {
    ...super.protectedColumns,
    'benchmark_id',
  };

  static void _validate(Map<String, Expression<Object>> columns) {
    _checkDates(columns, days: {'performed_on'});
    for (final key in ['value', 'bodyweight_kg', 'added_kg', 'edge_mm']) {
      final value = columns[key];
      if (value is Variable<Object> && value.value is double) {
        final number = value.value! as double;
        if (!number.isFinite || (key != 'value' && number < 0)) {
          throw ArgumentError.value(number, key);
        }
      }
    }
  }

  @override
  Future<void> update(
    String id,
    Insertable<BenchmarkResult> changes, {
    required String userId,
  }) {
    _validate(changes.toColumns(true));
    return super.update(id, changes, userId: userId);
  }

  /// Adds a result for [userId] on a test they can see. Returns the new id.
  Future<String> create(
    BenchmarkResultsCompanion draft, {
    required String userId,
  }) {
    if (!draft.benchmarkId.present || !draft.performedOn.present) {
      throw ArgumentError.value(draft, 'draft', 'needs a test and a date');
    }
    checkVisibility(draft.visibility.value);
    _validate(draft.toColumns(true));
    final benchmarkId = draft.benchmarkId.value;
    return db.transaction(() async {
      final def =
          await (db.select(db.benchmarkDefs)..where(
                (d) =>
                    d.id.equals(benchmarkId) &
                    d.deletedAt.isNull() &
                    (d.ownerId.isNull() | d.ownerId.equals(userId)),
              ))
              .getSingleOrNull();
      if (def == null) throw ArgumentError.value(benchmarkId, 'benchmarkId');
      final id = newId();
      final now = clock();
      await insert(
        draft.copyWith(
          id: Value(id),
          createdAt: Value(now),
          updatedAt: Value(now),
          deletedAt: const Value(null),
          ownerId: Value(userId),
        ),
      );
      return id;
    });
  }

  /// [userId]'s results on one test, oldest first, for progress charts.
  Stream<List<BenchmarkResult>> watchFor(
    String benchmarkId, {
    required String userId,
  }) {
    final query = live()
      ..where(
        (r) => r.benchmarkId.equals(benchmarkId) & r.ownerId.equals(userId),
      )
      ..orderBy([
        (r) => OrderingTerm(expression: r.performedOn),
        (r) => OrderingTerm(expression: r.createdAt),
      ]);
    return query.watch();
  }
}

/// Routes a user is working on.
class ProjectRepository extends Repository<$ProjectsTable, Project> {
  new(super.db, {super.clock});

  @override
  $ProjectsTable get table => db.projects;
  @override
  RowAccess get access => RowAccess.owned;

  /// A project is about one route.
  @override
  Set<String> get protectedColumns => {
    ...super.protectedColumns,
    'route_id',
    'sent_ascent_id',
  };

  static const statuses = {'active', 'sent', 'paused', 'abandoned'};

  static void _validate(Map<String, Expression<Object>> columns) {
    _checkDates(columns, days: {'started_on'});
    _checkOneOf('status', _text(columns, 'status'), statuses);
  }

  @override
  Future<void> update(
    String id,
    Insertable<Project> changes, {
    required String userId,
  }) {
    _validate(changes.toColumns(true));
    return super.update(id, changes, userId: userId);
  }

  /// Marks a project sent by one of [userId]'s live ascents of its route.
  Future<void> markSent(
    String projectId,
    String ascentId, {
    required String userId,
  }) => db.transaction(() async {
    await checkWritable(projectId, userId);
    final project = (await get(projectId))!;
    final ascent =
        await (db.select(db.ascents)..where(
              (a) =>
                  a.id.equals(ascentId) &
                  a.ownerId.equals(userId) &
                  a.routeId.equals(project.routeId) &
                  a.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (ascent == null) throw ArgumentError.value(ascentId, 'ascentId');
    await writeChecked(projectId, userId, {
      'status': const Variable('sent'),
      'sent_ascent_id': Variable(ascentId),
    });
  });

  /// Starts a project on a route [userId] can see. Returns the new id.
  Future<String> create(ProjectsCompanion draft, {required String userId}) {
    if (!draft.routeId.present || !draft.startedOn.present) {
      throw ArgumentError.value(draft, 'draft', 'needs a route and a date');
    }
    _validate(draft.toColumns(true));
    final routeId = draft.routeId.value;
    return db.transaction(() async {
      final route =
          await (db.select(db.routes)..where(
                (r) =>
                    r.id.equals(routeId) &
                    r.deletedAt.isNull() &
                    (r.visibility.equals('public') |
                        r.createdBy.equals(userId)),
              ))
              .getSingleOrNull();
      if (route == null) throw ArgumentError.value(routeId, 'routeId');
      final id = newId();
      final now = clock();
      await insert(
        draft.copyWith(
          id: Value(id),
          createdAt: Value(now),
          updatedAt: Value(now),
          deletedAt: const Value(null),
          ownerId: Value(userId),
          sentAscentId: const Value(null),
        ),
      );
      return id;
    });
  }

  /// [userId]'s projects with [status] (all when `null`), newest first.
  Stream<List<Project>> watchMine({required String userId, String? status}) {
    final query = live()
      ..where(
        (p) =>
            p.ownerId.equals(userId) &
            (status == null ? const Constant(true) : p.status.equals(status)),
      )
      ..orderBy([(p) => OrderingTerm.desc(p.startedOn)]);
    return query.watch();
  }
}

/// Goals, for example a grade, a count or a first.
class GoalRepository extends Repository<$GoalsTable, Goal>
    with ChangeVisibility<$GoalsTable, Goal> {
  new(super.db, {super.clock});

  @override
  $GoalsTable get table => db.goals;
  @override
  RowAccess get access => RowAccess.owned;

  static void _validate(Map<String, Expression<Object>> columns) {
    _checkDates(columns, days: {'deadline', 'achieved_on'});
    _checkOneOf('kind', _text(columns, 'kind'), {
      'grade',
      'count',
      'first',
      'benchmark',
    });
    _checkOneOf('status', _text(columns, 'status'), {
      'active',
      'achieved',
      'abandoned',
    });
  }

  @override
  Future<void> update(
    String id,
    Insertable<Goal> changes, {
    required String userId,
  }) {
    _validate(changes.toColumns(true));
    return super.update(id, changes, userId: userId);
  }

  /// Adds a goal for [userId]. Returns the new id.
  Future<String> create(GoalsCompanion draft, {required String userId}) async {
    checkVisibility(draft.visibility.value);
    _validate(draft.toColumns(true));
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
        ownerId: Value(userId),
      ),
    );
    return id;
  }

  /// [userId]'s goals with [status] (all when `null`), soonest deadline
  /// first and open-ended ones last.
  Stream<List<Goal>> watchMine({required String userId, String? status}) {
    final query = live()
      ..where(
        (g) =>
            g.ownerId.equals(userId) &
            (status == null ? const Constant(true) : g.status.equals(status)),
      )
      ..orderBy([
        (g) => OrderingTerm(expression: g.deadline.isNull()),
        (g) => OrderingTerm(expression: g.deadline),
        (g) => OrderingTerm(expression: g.createdAt),
      ]);
    return query.watch();
  }
}
