import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';

/// Who may change a row: its owner, or for shared tables the creator of a
/// row that is still private (docs/schema.md, Ownership and Shared rows).
enum RowAccess { owned, shared }

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

  GeneratedColumn<String> _column(String name) =>
      table.columnsByName[name]! as GeneratedColumn<String>;

  GeneratedColumn<String> get _id => _column('id');
  GeneratedColumn<DateTime> get _deletedAt =>
      table.columnsByName['deleted_at']! as GeneratedColumn<DateTime>;

  /// Live rows only: soft-deleted rows are invisible to screens.
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
  /// `updated_at`. Throws [NotYourRow] otherwise.
  Future<void> update(
    String id,
    Insertable<R> changes, {
    required String userId,
  }) => db.transaction(() async {
    await checkWritable(id, userId);
    final query = db.update(table)..where((_) => _id.equals(id));
    await query.write(changes);
    await query.write(
      RawValuesInsertable<R>({'updated_at': Variable(clock())}),
    );
  });

  /// Marks a row [userId] may change as deleted. Rows are never removed
  /// by clients, so the delete syncs. Throws [NotYourRow] otherwise.
  Future<void> softDelete(String id, {required String userId}) =>
      db.transaction(() async {
        await checkWritable(id, userId);
        await markDeleted(table, [id]);
      });

  /// For subclasses: sets `deleted_at` on [ids] in any [table], for
  /// cascades.
  Future<void> markDeleted(
    TableInfo<Table, Object?> table,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
    final now = clock();
    await db.customUpdate(
      // The table name comes from the generated table, never from input.
      'UPDATE ${table.actualTableName} SET deleted_at = ?, updated_at = ? '
      'WHERE id IN (${List.filled(ids.length, '?').join(', ')}) '
      'AND deleted_at IS NULL',
      variables: [
        Variable<DateTime>(now),
        Variable<DateTime>(now),
        for (final id in ids) Variable.withString(id),
      ],
      updates: {table},
      updateKind: UpdateKind.update,
    );
  }

  /// Throws [NotYourRow] unless the live row exists and [userId] may
  /// change it.
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
