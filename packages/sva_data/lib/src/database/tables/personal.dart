import 'package:drift/drift.dart';
import 'package:sva_data/src/database/tables/conventions.dart';

// Media, gear, shoes, projects, goals and training (docs/schema.md §5–8).

@TableIndex(name: 'media_session', columns: {#sessionId})
@DataClassName('MediaItem')
class Media extends Table with SyncedRow, Visible {
  /// Null once the photo is shared as a topo.
  TextColumn get ownerId => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get routeId => text().nullable()();
  TextColumn get ascentId => text().nullable()();

  /// `photo` or `video`.
  TextColumn get kind => text()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  RealColumn get durationS => real().nullable()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  IntColumn get sort => integer().clientDefault(() => 0)();

  /// `local`, `uploading`, `uploaded`, `failed`.
  TextColumn get uploadState => text()();

  /// Must be true before upload.
  /// `none`, `pending`, `shared`, `rejected`: sharing as a topo photo.
  TextColumn get shareState => text().clientDefault(() => 'none')();

  /// The person who took a shared topo photo.
  TextColumn get creditedTo => text().nullable()();

  BoolColumn get exifStripped => boolean().clientDefault(() => false)();
}

/// Shared gear catalog.
class GearModels extends Table with SyncedRow, SharedRow {
  TextColumn get brand => text()();
  TextColumn get model => text()();
  TextColumn get category => text()();
  TextColumn get sizeLabel => text().nullable()();
  TextColumn get colourHex => text().nullable()();

  /// JSON: range in mm, strength in kN, weight in g, length.
  TextColumn get specs => text().nullable()();
}

/// Each physical piece of gear you own.
class GearPieces extends Table with SyncedRow, OwnedRow {
  TextColumn get modelId => text().nullable()();
  TextColumn get category => text()();
  TextColumn get label => text()();
  TextColumn get colourHex => text().nullable()();
  TextColumn get serial => text().nullable()();

  /// `YYYY-MM`.
  TextColumn get madeOn => text().nullable()();
  TextColumn get boughtOn => text().nullable()();
  TextColumn get reslungOn => text().nullable()();
  IntColumn get reslingIntervalMonths => integer().nullable()();
  IntColumn get retireAfterMonths => integer().nullable()();
  BoolColumn get remind => boolean().clientDefault(() => true)();
  BoolColumn get inDefaultRack => boolean().clientDefault(() => false)();
  TextColumn get specs => text().nullable()();
  TextColumn get retiredOn => text().nullable()();
  TextColumn get notes => text().nullable()();
}

class GearEvents extends Table with SyncedRow, OwnedRow {
  TextColumn get pieceId => text()();

  /// `reslung`, `inspected`, `fall_held`, `lent`, `retired`.
  TextColumn get kind => text()();

  /// `YYYY-MM-DD`.
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();
}

class Shoes extends Table with SyncedRow, OwnedRow {
  TextColumn get brand => text()();
  TextColumn get model => text()();
  TextColumn get sizeLabel => text().nullable()();
  TextColumn get colourHex => text().nullable()();

  /// `velcro`, `lace`, `slipper`.
  TextColumn get closure => text().nullable()();

  /// JSON array: `gym`, `sport`, `boulder`, `trad`, `ice`.
  TextColumn get defaultFor => text().nullable()();
  TextColumn get boughtOn => text().nullable()();
  IntColumn get resoleAfterDays => integer().nullable()();
  TextColumn get retiredOn => text().nullable()();
  TextColumn get notes => text().nullable()();
}

class ShoeResoles extends Table with SyncedRow, OwnedRow {
  TextColumn get shoeId => text()();

  /// `YYYY-MM-DD`.
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();
}

class TicklistItems extends Table with SyncedRow, OwnedRow {
  TextColumn get routeId => text()();
  TextColumn get addedOn => text()();
  IntColumn get priority => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get doneAscentId => text().nullable()();
}

class Projects extends Table with SyncedRow, OwnedRow {
  TextColumn get routeId => text()();
  TextColumn get startedOn => text()();

  /// `active`, `sent`, `paused`, `abandoned`.
  TextColumn get status => text()();
  TextColumn get highPoint => text().nullable()();
  TextColumn get betaNotes => text().nullable()();
  TextColumn get sentAscentId => text().nullable()();
}

class Goals extends Table with SyncedRow, OwnedRow, Visible {
  /// `grade`, `count`, `first`, `benchmark`.
  TextColumn get kind => text()();

  /// JSON: metric, filters and threshold.
  TextColumn get target => text()();
  TextColumn get deadline => text().nullable()();

  /// `active`, `achieved`, `abandoned`.
  TextColumn get status => text()();
  TextColumn get achievedOn => text().nullable()();
  TextColumn get sourceGap => text().nullable()();
}

/// Standard tests (no owner) and the user's own.
class BenchmarkDefs extends Table with SyncedRow {
  /// Null for the standard tests that ship with Sva.
  TextColumn get ownerId => text().nullable()();
  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get protocol => text().nullable()();

  /// `pct_bw`, `kg`, `s`, `reps`, `cm`, `deg`.
  TextColumn get unit => text()();
  BoolColumn get higherIsBetter => boolean()();
}

class BenchmarkResults extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get benchmarkId => text()();
  TextColumn get performedOn => text()();
  RealColumn get value => real()();
  RealColumn get bodyweightKg => real().nullable()();
  RealColumn get addedKg => real().nullable()();
  RealColumn get edgeMm => real().nullable()();
  TextColumn get grip => text().nullable()();
  IntColumn get durationS => integer().nullable()();
  TextColumn get notes => text().nullable()();
}
