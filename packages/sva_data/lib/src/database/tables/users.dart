import 'package:drift/drift.dart';
import 'package:sva_data/src/database/tables/conventions.dart';

/// One per user; `id` is the Supabase Auth user ID (docs/schema.md §1).
class Profiles extends Table with SyncedRow {
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarMediaId => text().nullable()();
  TextColumn get homeAreaId => text().nullable()();
  TextColumn get defaultVisibility => text()();
  TextColumn get rackVisibility => text()();

  /// JSON: display grade system per grade type.
  TextColumn get gradePrefs => text().nullable()();

  /// `system`, `midnight` or `daylight`.
  TextColumn get theme => text()();

  /// `nb` or `en`; `null` follows the phone's language.
  TextColumn get language => text().nullable()();

  /// JSON: start and end of quiet hours for notifications.
  TextColumn get quietHours => text().nullable()();
}
