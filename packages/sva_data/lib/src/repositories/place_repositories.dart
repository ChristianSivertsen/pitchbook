import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/repositories/repository.dart';

/// Escapes `%`, `_` and `\` so a search term matches itself in LIKE.
String _likePattern(String term) =>
    '%${term.trim().replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';

/// Countries, regions, crags, sectors, walls, boulders and gyms.
class AreaRepository extends Repository<$AreasTable, Area> {
  new(super.db, {super.clock});

  @override
  $AreasTable get table => db.areas;
  @override
  RowAccess get access => RowAccess.shared;

  /// Adds a place as [userId]'s private row; it becomes shared when a
  /// moderator accepts it (docs/schema.md, How a route becomes shared).
  /// Returns the new id.
  Future<String> createPrivate(
    AreasCompanion draft, {
    required String userId,
  }) async {
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdBy: Value(userId),
        visibility: const Value('private'),
      ),
    );
    return id;
  }

  /// The places directly under [parentId] (top-level ones when `null`),
  /// by name. Others' private places are left out.
  Stream<List<Area>> watchChildren(String? parentId, {required String userId}) {
    final query = live()
      ..where(
        (a) =>
            (parentId == null
                ? a.parentId.isNull()
                : a.parentId.equals(parentId)) &
            _visibleTo(a, userId),
      )
      ..orderBy([(a) => OrderingTerm(expression: a.name)]);
    return query.watch();
  }

  /// Places whose name contains [term], up to [limit], by name.
  Future<List<Area>> search(
    String term, {
    required String userId,
    int limit = 30,
  }) {
    final query = live()
      ..where(
        (a) =>
            a.name.like(_likePattern(term), escapeChar: r'\') &
            _visibleTo(a, userId),
      )
      ..orderBy([(a) => OrderingTerm(expression: a.name)])
      ..limit(limit);
    return query.get();
  }

  static Expression<bool> _visibleTo($AreasTable a, String userId) =>
      a.visibility.equals('public') | a.createdBy.equals(userId);
}

/// Every climbable line, outdoors or in a gym.
class RouteRepository extends Repository<$RoutesTable, Route> {
  new(super.db, {super.clock});

  @override
  $RoutesTable get table => db.routes;
  @override
  RowAccess get access => RowAccess.shared;

  /// Adds a route as [userId]'s private route. Gym routes stay private.
  /// Returns the new id.
  Future<String> createPrivate(
    RoutesCompanion draft, {
    required String userId,
  }) async {
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdBy: Value(userId),
        visibility: const Value('private'),
      ),
    );
    return id;
  }

  /// The routes in one place, by name, without others' private routes.
  Stream<List<Route>> watchInArea(String areaId, {required String userId}) {
    final query = live()
      ..where((r) => r.areaId.equals(areaId) & _visibleTo(r, userId))
      ..orderBy([(r) => OrderingTerm(expression: r.name)]);
    return query.watch();
  }

  /// Outdoor routes whose name contains [term], up to [limit]. Gym routes
  /// never appear in the outdoor route list (PLAN.md 4).
  Future<List<Route>> search(
    String term, {
    required String userId,
    int limit = 30,
  }) {
    final query = live()
      ..where(
        (r) =>
            r.kind.equals('outdoor') &
            r.name.like(_likePattern(term), escapeChar: r'\') &
            _visibleTo(r, userId),
      )
      ..orderBy([(r) => OrderingTerm(expression: r.name)])
      ..limit(limit);
    return query.get();
  }

  static Expression<bool> _visibleTo($RoutesTable r, String userId) =>
      r.visibility.equals('public') | r.createdBy.equals(userId);
}

/// A user's own walls in a gym; gyms themselves are shared areas.
class GymWallRepository extends Repository<$GymWallsTable, GymWall> {
  new(super.db, {super.clock});

  @override
  $GymWallsTable get table => db.gymWalls;
  @override
  RowAccess get access => RowAccess.owned;

  /// Adds a wall for [userId]. Returns the new id.
  Future<String> create(
    GymWallsCompanion draft, {
    required String userId,
  }) async {
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        ownerId: Value(userId),
      ),
    );
    return id;
  }

  /// [userId]'s walls in [gymId], in their order.
  Stream<List<GymWall>> watchInGym(String gymId, {required String userId}) {
    final query = live()
      ..where((w) => w.gymId.equals(gymId) & w.ownerId.equals(userId))
      ..orderBy([
        (w) => OrderingTerm(expression: w.sort),
        (w) => OrderingTerm(expression: w.name),
      ]);
    return query.watch();
  }
}

/// A user's own colour scale for a gym, easiest first.
class GymColourGradeRepository
    extends Repository<$GymColourGradesTable, GymColourGrade> {
  new(super.db, {super.clock});

  @override
  $GymColourGradesTable get table => db.gymColourGrades;
  @override
  RowAccess get access => RowAccess.owned;

  /// Adds a colour for [userId]. Returns the new id.
  Future<String> create(
    GymColourGradesCompanion draft, {
    required String userId,
  }) async {
    final id = newId();
    final now = clock();
    await insert(
      draft.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
        ownerId: Value(userId),
      ),
    );
    return id;
  }

  /// [userId]'s colours for [gymId], easiest first.
  Stream<List<GymColourGrade>> watchForGym(
    String gymId, {
    required String userId,
  }) {
    final query = live()
      ..where((g) => g.gymId.equals(gymId) & g.ownerId.equals(userId))
      ..orderBy([(g) => OrderingTerm(expression: g.sort)]);
    return query.watch();
  }
}
