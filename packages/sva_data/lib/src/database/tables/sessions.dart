import 'package:drift/drift.dart';
import 'package:sva_data/src/database/tables/conventions.dart';

// Trips, sessions and ascents (docs/schema.md §4).
//
// A session's child rows (ascents and their pitches, attributes and gear,
// members, weather) carry a copy of the session's `visibility`, so a sync
// rule or row-level security policy can decide on the row alone, without
// a join. Repositories update the copies when the session's visibility
// changes.

class Trips extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get name => text()();

  /// `YYYY-MM-DD`.
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get areaId => text().nullable()();
  TextColumn get description => text().nullable()();
}

class TripMembers extends Table with SyncedRow, OwnedRow {
  TextColumn get tripId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get guestName => text().nullable()();

  /// `pending`, `accepted`, `declined`, `guest`.
  TextColumn get status => text()();
}

/// Links the partners' copies of a shared session.
class ClimbGroups extends Table with SyncedRow, OwnedRow;

@TableIndex(name: 'sessions_owner_date', columns: {#ownerId, #localDate})
class Sessions extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get tripId => text().nullable()();
  TextColumn get climbGroupId => text().nullable()();
  TextColumn get areaId => text().nullable()();

  /// `outdoor` or `indoor`.
  TextColumn get setting => text()();

  /// `YYYY-MM-DD` in the session's own time zone.
  TextColumn get localDate => text()();

  /// IANA time zone, for example `Europe/Oslo`.
  TextColumn get tz => text()();
  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get locationHidden => boolean().clientDefault(() => false)();
  TextColumn get defaultShoeId => text().nullable()();
  IntColumn get elevationGainM => integer().nullable()();
  TextColumn get conditions => text().nullable()();
}

class WeatherSnapshots extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get sessionId => text()();

  /// `open_meteo`.
  TextColumn get source => text()();
  RealColumn get tempC => real().nullable()();
  RealColumn get precipMm => real().nullable()();
  RealColumn get windMs => real().nullable()();
  RealColumn get humidityPct => real().nullable()();
  RealColumn get cloudPct => real().nullable()();
  RealColumn get waterTempC => real().nullable()();

  /// JSON: the provider's full answer.
  TextColumn get raw => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
}

@TableIndex(name: 'session_members_user_status', columns: {#userId, #status})
class SessionMembers extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get sessionId => text()();

  /// Null for partners without the app.
  TextColumn get userId => text().nullable()();
  TextColumn get guestName => text().nullable()();

  /// `pending`, `accepted`, `declined`, `guest`.
  TextColumn get status => text()();
  TextColumn get invitedBy => text().nullable()();
}

@TableIndex(
  name: 'ascents_owner_setting_discipline',
  columns: {#ownerId, #setting, #discipline},
)
@TableIndex(name: 'ascents_owner_route', columns: {#ownerId, #routeId})
@TableIndex(name: 'ascents_session', columns: {#sessionId})
class Ascents extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get sessionId => text()();
  TextColumn get routeId => text()();
  IntColumn get ordinal => integer()();
  TextColumn get ascentType => text()();

  /// `onsight`, `flash`, `redpoint`, `repeat`, `attempt`.
  TextColumn get style => text()();
  IntColumn get tries => integer()();
  IntColumn get falls => integer().nullable()();
  IntColumn get rests => integer().nullable()();
  TextColumn get highPoint => text().nullable()();
  TextColumn get feel => text().nullable()();
  TextColumn get personalGradeId => text().nullable()();
  TextColumn get officialGradeId => text().nullable()();
  RealColumn get difficultyScore => real().nullable()();
  IntColumn get qualityStars => integer().nullable()();

  IntColumn get durationS => integer().nullable()();
  TextColumn get shoeId => text().nullable()();

  /// Caches from the session and route, for stats queries.
  TextColumn get setting => text()();
  TextColumn get discipline => text()();
}

/// Beta notes on an ascent. Always private, so they live in their own
/// owner-only table that no shared sync rule or view can reach.
@DataClassName('AscentBetaNote')
class AscentBeta extends Table with SyncedRow, OwnedRow {
  TextColumn get ascentId => text()();
  TextColumn get betaNotes => text()();
}

@DataClassName('AscentPitch')
class AscentPitches extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get ascentId => text()();
  TextColumn get pitchId => text().nullable()();
  IntColumn get number => integer()();

  /// `self`, `partner`, `simul`, `none`.
  TextColumn get leader => text()();
  TextColumn get leaderMemberId => text().nullable()();
  TextColumn get style => text().nullable()();
  IntColumn get falls => integer().nullable()();
  IntColumn get rests => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

@TableIndex(
  name: 'ascent_attributes_key_value',
  columns: {#attributeKey, #value},
)
class AscentAttributes extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get ascentId => text()();
  TextColumn get attributeKey => text()();
  TextColumn get value => text()();
}

/// The rack taken on one climb.
@DataClassName('AscentGearItem')
class AscentGear extends Table with SyncedRow, OwnedRow, Visible {
  TextColumn get ascentId => text()();
  TextColumn get gearPieceId => text()();
  IntColumn get count => integer().clientDefault(() => 1)();
  TextColumn get borrowedFrom => text().nullable()();
}
