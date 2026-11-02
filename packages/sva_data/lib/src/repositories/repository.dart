import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';

/// Who may change a row: its owner, or for shared tables the creator of a
/// row that is still private (docs/schema.md, Ownership and Shared rows).
enum RowAccess { owned, shared }

/// Who can see a user's row (docs/schema.md, Visibility).
const visibilities = {'public', 'friends', 'private'};

/// Throws [ArgumentError] unless [visibility] is one of [visibilities].
void checkVisibility(String visibility) {
  if (!visibilities.contains(visibility)) {
    throw ArgumentError.value(visibility, 'visibility');
  }
}

/// Thrown when a user tries to change a row that is not theirs to change.
class NotYourRow implements Exception {
  new(this.table, this.id);

  final String table;
  final String id;

  @override
  String toString() => 'NotYourRow: $table $id';
}

/// The common part of every repository: reading live rows, stamping new
/// ones, updating with a fresh `updated_at`, and soft deletes. Screens use
/// the concrete repositories, never SQL.
abstract class Repository<T extends Table, R> {
  new(this.db, {DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now().toUtc());

  final SvaDatabase db;
  final DateTime Function() clock;

  TableInfo<T, R> get table;
  RowAccess get access;

  /// Columns [update] never changes. Identity, ownership, timestamps and
  /// visibility change only through dedicated methods (or, for shared rows,
  /// moderated requests); subclasses add their own caches.
  Set<String> get protectedColumns => const {
    'id',
    'owner_id',
    'created_by',
    'created_at',
    'updated_at',
    'deleted_at',
    'visibility',
    'merged_into_id',
    'consensus_score',
    'quality_avg',
  };

  GeneratedColumn<String> get _id =>
      table.columnsByName['id']! as GeneratedColumn<String>;
  GeneratedColumn<DateTime> get _deletedAt =>
      table.columnsByName['deleted_at']! as GeneratedColumn<DateTime>;

  /// For subclasses: live rows only. Soft-deleted rows are invisible to
  /// screens.
  SimpleSelectStatement<T, R> live() =>
      db.select(table)..where((_) => _deletedAt.isNull());

  /// The live row with [id], or `null`.
  Future<R?> get(String id) =>
      (live()..where((_) => _id.equals(id))).getSingleOrNull();

  /// The live row with [id], updating whenever it changes.
  Stream<R?> watch(String id) =>
      (live()..where((_) => _id.equals(id))).watchSingleOrNull();

  /// For subclasses: inserts [row], which already carries its id and
  /// timestamps.
  Future<void> insert(Insertable<R> row) => db.into(table).insert(row);

  /// Applies [changes] to a row [userId] may change, with a new
  /// `updated_at`. Throws [ArgumentError] when [changes] touches a
  /// [protectedColumns] column and [NotYourRow] when the row is not theirs.
  Future<void> update(
    String id,
    Insertable<R> changes, {
    required String userId,
  }) {
    final columns = changes.toColumns(true);
    final blocked = columns.keys.where(protectedColumns.contains).toList();
    if (blocked.isNotEmpty) {
      throw ArgumentError.value(blocked, 'changes', 'protected columns');
    }
    return writeChecked(id, userId, {...columns, ...derivedColumns(columns)});
  }

  /// For subclasses: columns computed from [changes], such as search keys
  /// from a name, written in the same statement.
  Map<String, Expression<Object>> derivedColumns(
    Map<String, Expression<Object>> changes,
  ) => const {};

  /// For subclasses: checks [userId] may change the row, then writes
  /// [columns] with a new `updated_at` in one statement.
  Future<void> writeChecked(
    String id,
    String userId,
    Map<String, Expression<Object>> columns,
  ) => db.transaction(() async {
    await checkWritable(id, userId);
    if (columns.isEmpty) return;
    await (db.update(table)..where((_) => _id.equals(id))).write(
      RawValuesInsertable<R>({...columns, 'updated_at': Variable(clock())}),
    );
  });

  /// Marks a row [userId] may change as deleted. Rows are never removed
  /// by clients, so the delete syncs. Throws [NotYourRow] otherwise.
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        await markDeleted(table, _id, [id]);
      });

  /// For subclasses: sets `deleted_at` on the live rows of [table] whose
  /// [key] is in [keys], for cascades.
  Future<void> markDeleted(
    TableInfo<Table, Object?> table,
    GeneratedColumn<String> key,
    List<String> keys,
  ) async {
    if (keys.isEmpty) return;
    final now = clock();
    await db.customUpdate(
      // Names come from the generated table, never from input.
      'UPDATE ${table.actualTableName} SET deleted_at = ?, updated_at = ? '
      'WHERE ${key.name} IN (${List.filled(keys.length, '?').join(', ')}) '
      'AND deleted_at IS NULL',
      variables: [
        Variable<DateTime>(now),
        Variable<DateTime>(now),
        for (final k in keys) Variable.withString(k),
      ],
      updates: {table},
      updateKind: UpdateKind.update,
    );
  }

  /// For subclasses: throws [NotYourRow] unless the live row exists and
  /// [userId] may change it.
  Future<void> checkWritable(String id, String userId) async {
    final columns = access == RowAccess.owned
        ? ['owner_id']
        : ['created_by', 'visibility'];
    final row = await db
        .customSelect(
          // Names come from constants and the generated table, never input.
          'SELECT ${columns.join(', ')} FROM ${table.actualTableName} '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable.withString(id)],
          readsFrom: {table},
        )
        .getSingleOrNull();
    final allowed = switch (access) {
      RowAccess.owned => row?.data['owner_id'] == userId,
      RowAccess.shared =>
        row?.data['created_by'] == userId &&
            row?.data['visibility'] == 'private',
    };
    if (!allowed) throw NotYourRow(table.actualTableName, id);
  }
}

/// For owned rows that others may see but that have no child rows to keep
/// in step (goals, benchmark results): visibility changes only here.
mixin ChangeVisibility<T extends Table, R> on Repository<T, R> {
  /// Sets who can see one of [userId]'s rows.
  Future<void> setVisibility(
    String id,
    String visibility, {
    required String userId,
  }) {
    checkVisibility(visibility);
    return writeChecked(id, userId, {'visibility': Variable(visibility)});
  }
}
