import 'package:drift/drift.dart';

// Every table follows the conventions in docs/schema.md, and the limits of
// PowerSync, which takes over the synced tables in M11-4:
// - a text `id` primary key (UUIDv7), also on join tables;
// - no foreign keys, check constraints or unique indexes. Rules are
//   enforced in sva_core, the repositories and Postgres instead;
// - only text, integer and real columns: booleans are integers, JSON and
//   dates are text, timestamps are ISO 8601 text (see build.yaml).

/// Columns on every table: id and the sync timestamps.
mixin SyncedRow on Table {
  /// UUIDv7, generated on the device.
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set instead of deleting; clients never hard-delete rows.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A row that belongs to one user. Only the owner may change it.
mixin OwnedRow on SyncedRow {
  TextColumn get ownerId => text()();
}

/// A row in the shared database (places, routes, grades, catalogs).
/// Clients never change these directly once shared.
mixin SharedRow on SyncedRow {
  /// Null for rows seeded by Sva.
  TextColumn get createdBy => text().nullable()();
}

/// `public`, `friends` or `private`.
mixin Visible on Table {
  TextColumn get visibility => text()();
}
