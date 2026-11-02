import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/repositories/place_repositories.dart' show LatLon;
import 'package:sva_data/src/weather/open_meteo.dart';

/// Adds the weather to outdoor sessions that do not have it yet. Logging
/// never waits for it: a session saved without signal gets its weather the
/// next time this runs with a connection (on start, after each save, and
/// every few minutes while the app is open).
class WeatherFiller {
  new(this.db, this._weather, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final SvaDatabase db;
  final OpenMeteo _weather;
  final DateTime Function() _clock;

  /// The run in progress, so overlapping calls do not fetch twice.
  Future<int>? _running;

  /// Fetches the weather for each of [userId]'s outdoor sessions that has
  /// a place but no weather yet. Returns how many sessions got weather.
  /// Stops at the first network error and tries again on the next call.
  Future<int> fillMissing({required String userId}) =>
      _running ??= _fill(userId).whenComplete(() => _running = null);

  Future<int> _fill(String userId) async {
    var filled = 0;
    for (final session in await _waiting(userId)) {
      final WeatherDay? day;
      try {
        day = await _weather.day(session.at, session.localDate);
      } on Exception {
        // No connection (or a timeout): the rest can wait too.
        break;
      }
      if (day == null) continue;
      final now = _clock();
      final temp = switch ((day.tempMaxC, day.tempMinC)) {
        (final max?, final min?) => (max + min) / 2,
        (final max?, null) => max,
        (null, final min?) => min,
        (null, null) => null,
      };
      await db
          .into(db.weatherSnapshots)
          .insert(
            WeatherSnapshotsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              ownerId: userId,
              visibility: session.visibility,
              sessionId: session.id,
              source: 'open_meteo',
              tempC: Value(temp),
              precipMm: Value(day.precipMm),
              windMs: Value(day.windMs),
              raw: Value(day.raw),
              fetchedAt: now,
            ),
          );
      filled++;
    }
    return filled;
  }

  /// [userId]'s live outdoor sessions, up to today, that have no weather
  /// yet but a place to look it up for: the session's place, or else its
  /// first climb's, up to three levels up. Newest first.
  Future<List<({String id, String localDate, String visibility, LatLon at})>>
  _waiting(String userId) async {
    final today = _clock().toIso8601String().substring(0, 10);
    final rows = await db
        .customSelect(
          'WITH places AS ( '
          'SELECT s.id, s.local_date, s.visibility, COALESCE(s.area_id, ( '
          'SELECT r.area_id FROM ascents x JOIN routes r ON r.id = x.route_id '
          'WHERE x.session_id = s.id AND x.deleted_at IS NULL '
          'ORDER BY x.ordinal LIMIT 1)) AS area_id '
          'FROM sessions s '
          'WHERE s.owner_id = ?1 AND s.deleted_at IS NULL '
          "AND s.setting = 'outdoor' AND s.local_date <= ?2 "
          'AND NOT EXISTS (SELECT 1 FROM weather_snapshots w '
          'WHERE w.session_id = s.id AND w.deleted_at IS NULL)) '
          'SELECT p.id, p.local_date, p.visibility, '
          'COALESCE(a1.latitude, a2.latitude, a3.latitude) AS lat, '
          'COALESCE(a1.longitude, a2.longitude, a3.longitude) AS lon '
          'FROM places p '
          'JOIN areas a1 ON a1.id = p.area_id '
          'LEFT JOIN areas a2 ON a2.id = a1.parent_id '
          'LEFT JOIN areas a3 ON a3.id = a2.parent_id '
          'WHERE COALESCE(a1.latitude, a2.latitude, a3.latitude) IS NOT NULL '
          'AND COALESCE(a1.longitude, a2.longitude, a3.longitude) IS NOT NULL '
          'ORDER BY p.local_date DESC',
          variables: [Variable.withString(userId), Variable.withString(today)],
          readsFrom: {
            db.sessions,
            db.ascents,
            db.routes,
            db.areas,
            db.weatherSnapshots,
          },
        )
        .get();
    return [
      for (final row in rows)
        (
          id: row.read<String>('id'),
          localDate: row.read<String>('local_date'),
          visibility: row.read<String>('visibility'),
          at: (lat: row.read<double>('lat'), lon: row.read<double>('lon')),
        ),
    ];
  }
}
