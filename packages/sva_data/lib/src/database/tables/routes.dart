import 'package:drift/drift.dart';
import 'package:sva_data/src/database/tables/conventions.dart';

@TableIndex(name: 'routes_area', columns: {#areaId})
/// Every climbable line, outdoors or in a gym (docs/schema.md §3).
class Routes extends Table with SyncedRow, SharedRow, Visible {
  TextColumn get areaId => text()();

  /// `outdoor` or `gym`.
  TextColumn get kind => text()();
  TextColumn get name => text().nullable()();

  /// `sport`, `trad`, `boulder`, `alpine`, `ice`, `mixed`, `aid`, `dws`.
  TextColumn get discipline => text()();
  IntColumn get pitchCount => integer().withDefault(const Constant(1))();
  RealColumn get lengthM => real().nullable()();
  TextColumn get angle => text().nullable()();
  TextColumn get protection => text().nullable()();
  TextColumn get descent => text().nullable()();
  IntColumn get ropeLengthM => integer().nullable()();
  TextColumn get ropeType => text().nullable()();
  RealColumn get waterDepthM => real().nullable()();
  BoolColumn get tideDependent => boolean().nullable()();
  TextColumn get seasonNotes => text().nullable()();
  TextColumn get firstAscent => text().nullable()();
  IntColumn get firstAscentYear => integer().nullable()();

  /// `open`, `closed`, `seasonal`, `retired`.
  TextColumn get status => text()();
  RealColumn get consensusScore => real().nullable()();
  RealColumn get qualityAvg => real().nullable()();
  TextColumn get gymWallId => text().nullable()();
  TextColumn get gymColourGradeId => text().nullable()();

  /// `YYYY-MM-DD`, gym routes only.
  TextColumn get setOn => text().nullable()();
  TextColumn get expiresOn => text().nullable()();
  TextColumn get setterNote => text().nullable()();
  TextColumn get mergedIntoId => text().nullable()();
}

@DataClassName('Pitch')
class Pitches extends Table with SyncedRow, SharedRow {
  TextColumn get routeId => text()();
  IntColumn get number => integer()();
  RealColumn get lengthM => real().nullable()();
  TextColumn get angle => text().nullable()();
  TextColumn get protection => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get anchor => text().nullable()();
  TextColumn get belayNotes => text().nullable()();
}

/// Shared grade system definitions, stored as data.
class GradeSystems extends Table with SyncedRow, SharedRow {
  /// Stable key such as `nor`, `font`, `wi`.
  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get gradeType => text()();
  IntColumn get sort => integer()();
  TextColumn get region => text().nullable()();
}

class Grades extends Table with SyncedRow, SharedRow {
  TextColumn get systemKey => text()();
  TextColumn get label => text()();
  IntColumn get sort => integer()();

  /// Position on the shared difficulty scale for the grade type.
  RealColumn get score => real().nullable()();
  RealColumn get scoreLow => real().nullable()();
  RealColumn get scoreHigh => real().nullable()();
}

/// Any number of grades per route or pitch.
class RouteGrades extends Table with SyncedRow, SharedRow {
  TextColumn get routeId => text()();
  TextColumn get pitchId => text().nullable()();
  TextColumn get gradeType => text()();
  TextColumn get gradeId => text()();

  /// `official`, `guidebook`, `consensus`.
  TextColumn get source => text()();
}

/// Definitions for the long tail of details (features, holds, tags).
class AttributeDefs extends Table with SyncedRow, SharedRow {
  TextColumn get key => text()();

  /// `area`, `route`, `pitch`, `ascent`, `session`.
  TextColumn get level => text()();

  /// `single`, `multi`, `number`, `bool`.
  TextColumn get valueType => text()();

  /// JSON array of allowed value keys.
  TextColumn get valueKeys => text().nullable()();
  IntColumn get sort => integer()();
}

@TableIndex(
  name: 'route_attributes_key_value',
  columns: {#attributeKey, #value},
)
class RouteAttributes extends Table with SyncedRow, SharedRow {
  TextColumn get routeId => text()();
  TextColumn get attributeKey => text()();

  /// A key, number or boolean, as text.
  TextColumn get value => text()();
}

class Topos extends Table with SyncedRow, SharedRow {
  TextColumn get routeId => text().nullable()();
  TextColumn get areaId => text().nullable()();
  TextColumn get mediaId => text()();

  /// JSON: lines, symbols and labels relative to the photo.
  TextColumn get data => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// `draft` or `published`.
  TextColumn get status => text()();
}
