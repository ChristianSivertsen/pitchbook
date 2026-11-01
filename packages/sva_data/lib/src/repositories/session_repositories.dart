import 'package:drift/drift.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/repositories/repository.dart';

/// A day of climbing and everything under it.
class SessionRepository extends Repository<$SessionsTable, Session> {
  new(super.db, {super.clock});

  @override
  $SessionsTable get table => db.sessions;
  @override
  RowAccess get access => RowAccess.owned;

  /// Adds a session for [userId]. Returns the new id.
  Future<String> create(
    SessionsCompanion draft, {
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

  /// [userId]'s sessions, newest day first.
  Stream<List<Session>> watchMine({required String userId}) {
    final query = live()
      ..where((s) => s.ownerId.equals(userId))
      ..orderBy([
        (s) => OrderingTerm.desc(s.localDate),
        (s) => OrderingTerm.desc(s.createdAt),
      ]);
    return query.watch();
  }

  /// Changes who can see a session. The copies of its visibility on the
  /// session's child rows change with it, so sync rules decide on each row
  /// alone (docs/schema.md, Visibility).
  Future<void> setVisibility(
    String id,
    String visibility, {
    required String userId,
  }) => db.transaction(() async {
    await update(
      id,
      SessionsCompanion(visibility: Value(visibility)),
      userId: userId,
    );
    final now = clock();
    final ascentIds = await _ascentIds(id);
    final changes = {
      'visibility': Variable<String>(visibility),
      'updated_at': Variable<DateTime>(now),
    };
    for (final (children, column, keys) in _children(id, ascentIds)) {
      await db.customUpdate(
        'UPDATE $children SET visibility = ?, updated_at = ? '
        'WHERE $column IN (${List.filled(keys.length, '?').join(', ')}) '
        'AND deleted_at IS NULL',
        variables: [
          ...changes.values,
          for (final key in keys) Variable.withString(key),
        ],
        updates: {
          db.allTables.firstWhere((t) => t.actualTableName == children),
        },
        updateKind: UpdateKind.update,
      );
    }
  });

  /// Soft-deletes a session with its ascents and their child rows.
  @override
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        final ascentIds = await _ascentIds(id);
        await markDeleted(table, [id]);
        for (final (children, column, keys) in _children(id, ascentIds)) {
          final childTable = db.allTables.firstWhere(
            (t) => t.actualTableName == children,
          );
          final keyColumn =
              childTable.columnsByName[column]! as GeneratedColumn<String>;
          final idColumn =
              childTable.columnsByName['id']! as GeneratedColumn<String>;
          final rows =
              await (db.selectOnly(childTable)
                    ..addColumns([idColumn])
                    ..where(keyColumn.isIn(keys)))
                  .get();
          await markDeleted(childTable, [
            for (final r in rows) r.read(idColumn)!,
          ]);
        }
      });

  Future<List<String>> _ascentIds(String sessionId) async {
    final rows = await (db.select(
      db.ascents,
    )..where((a) => a.sessionId.equals(sessionId))).get();
    return [for (final a in rows) a.id];
  }

  // Child tables of a session: (table, key column, key values). Names are
  // constants, never input.
  List<(String, String, List<String>)> _children(
    String sessionId,
    List<String> ascentIds,
  ) => [
    ('ascents', 'session_id', [sessionId]),
    ('session_members', 'session_id', [sessionId]),
    ('weather_snapshots', 'session_id', [sessionId]),
    if (ascentIds.isNotEmpty) ...[
      ('ascent_pitches', 'ascent_id', ascentIds),
      ('ascent_attributes', 'ascent_id', ascentIds),
      ('ascent_gear', 'ascent_id', ascentIds),
    ],
  ];
}

/// Climbs logged in a session.
class AscentRepository extends Repository<$AscentsTable, Ascent> {
  new(super.db, {super.clock});

  @override
  $AscentsTable get table => db.ascents;
  @override
  RowAccess get access => RowAccess.owned;

  /// Adds an ascent to one of [userId]'s sessions. Owner, visibility and the
  /// setting and discipline caches come from the session and the route, not
  /// from the caller. Returns the new id.
  Future<String> create(AscentsCompanion draft, {required String userId}) =>
      db.transaction(() async {
        final sessionId = draft.sessionId.value;
        final routeId = draft.routeId.value;
        final session =
            await (db.select(db.sessions)
                  ..where((s) => s.id.equals(sessionId) & s.deletedAt.isNull()))
                .getSingleOrNull();
        if (session == null || session.ownerId != userId) {
          throw NotYourRow('sessions', sessionId);
        }
        final route = await (db.select(
          db.routes,
        )..where((r) => r.id.equals(routeId))).getSingleOrNull();
        if (route == null) throw ArgumentError.value(routeId, 'routeId');
        final id = newId();
        final now = clock();
        await insert(
          draft.copyWith(
            id: Value(id),
            createdAt: Value(now),
            updatedAt: Value(now),
            ownerId: Value(userId),
            visibility: Value(session.visibility),
            setting: Value(session.setting),
            discipline: Value(route.discipline),
          ),
        );
        return id;
      });

  /// The climbs in a session, in the order they were climbed.
  Stream<List<Ascent>> watchInSession(String sessionId) {
    final query = live()
      ..where((a) => a.sessionId.equals(sessionId))
      ..orderBy([(a) => OrderingTerm(expression: a.ordinal)]);
    return query.watch();
  }

  /// [userId]'s live ascents of a route, oldest first, in the form the
  /// style and tries rules take (sva_core `checkRouteLog`). The order is
  /// the session's local date, then the ascent's ordinal, as on the server.
  Future<List<LoggedAscent>> routeLog(
    String routeId, {
    required String userId,
  }) async {
    final query =
        db.select(db.ascents).join([
            innerJoin(
              db.sessions,
              db.sessions.id.equalsExp(db.ascents.sessionId),
            ),
          ])
          ..where(
            db.ascents.routeId.equals(routeId) &
                db.ascents.ownerId.equals(userId) &
                db.ascents.deletedAt.isNull() &
                db.sessions.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm(expression: db.sessions.localDate),
            OrderingTerm(expression: db.ascents.ordinal),
          ]);
    return [
      for (final row in await query.get())
        if (AscentStyle.values.asNameMap()[row.readTable(db.ascents).style]
            case final style?)
          (style: style, tries: row.readTable(db.ascents).tries),
    ];
  }
}
