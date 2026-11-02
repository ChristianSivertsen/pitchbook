import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  final today = DateTime.utc(2026, 11, 2, 12);
  DateTime clock() => today;

  setUp(() async {
    db = SvaDatabase.inMemory();
    await GradeRepository(db).seed();
    await AttributeRepository(db).seed();
  });
  tearDown(() => db.close());

  Future<String> logAt(String date) async {
    final editor = RouteEditor(db);
    final crag = await editor.addCrag(
      const NewCrag(
        name: 'Kolsås',
        countryCode: 'NO',
        location: (lat: 59.91834, lon: 10.50391),
      ),
      userId: 'me',
    );
    final route = await editor.addRoute(
      NewRoute(areaId: crag, name: 'Hjemmebane', discipline: 'sport'),
      userId: 'me',
    );
    return await SessionLogger(db, clock: clock).logOutdoor(
      SessionDraft(
        localDate: date,
        tz: 'Europe/Oslo',
        visibility: 'friends',
        climbs: [
          ClimbDraft(
            routeId: route,
            style: AscentStyle.onsight,
            tries: 1,
            ascentType: 'lead',
          ),
        ],
      ),
      userId: 'me',
    );
  }

  String answer(String date) => jsonEncode({
    'daily': {
      'time': [date],
      'temperature_2m_max': [14.2],
      'temperature_2m_min': [6.0],
      'precipitation_sum': [0.4],
      'wind_speed_10m_max': [3.1],
    },
  });

  test(
    'M2-5: a session saved without signal gets its weather once online',
    () async {
      final session = await logAt('2026-11-01');
      var online = false;
      final asked = <Uri>[];
      final client = MockClient((request) async {
        asked.add(request.url);
        if (!online) throw http.ClientException('no signal');
        return http.Response(answer('2026-11-01'), 200);
      });
      final filler = WeatherFiller(
        db,
        OpenMeteo(client: client, clock: clock),
        clock: clock,
      );

      expect(await filler.fillMissing(userId: 'me'), 0);
      expect(await db.select(db.weatherSnapshots).get(), isEmpty);
      expect(await SessionRepository(db).get(session), isNotNull);

      online = true;
      expect(await filler.fillMissing(userId: 'me'), 1);
      final weather = (await db.select(db.weatherSnapshots).get()).single;
      expect(weather.sessionId, session);
      expect(weather.tempC, closeTo(10.1, 0.01));
      expect(weather.precipMm, 0.4);
      expect(weather.windMs, 3.1);
      expect(weather.visibility, 'friends', reason: "the session's visibility");
      expect(await filler.fillMissing(userId: 'me'), 0, reason: 'only once');

      final url = asked.last;
      expect(url.host, 'api.open-meteo.com', reason: 'recent days: forecast');
      expect(url.queryParameters['latitude'], '59.92', reason: 'about 1 km');
      expect(url.queryParameters['start_date'], '2026-11-01');
    },
  );

  test(
    'M2-5: older days come from the archive, bad answers are ignored',
    () async {
      await logAt('2025-07-12');
      final asked = <Uri>[];
      final filler = WeatherFiller(
        db,
        OpenMeteo(
          client: MockClient((request) async {
            asked.add(request.url);
            return http.Response('{"daily": {"time": ["2025-07-13"]}}', 200);
          }),
          clock: clock,
        ),
        clock: clock,
      );
      // No weather for that day: stored as empty, never asked again.
      expect(await filler.fillMissing(userId: 'me'), 1);
      expect(await filler.fillMissing(userId: 'me'), 0);
      expect(asked.single.host, 'archive-api.open-meteo.com');
      expect((await db.select(db.weatherSnapshots).get()).single.tempC, isNull);

      final odd = OpenMeteo.parseDay(
        jsonEncode({
          'daily': {
            'time': ['2025-07-12'],
            'temperature_2m_max': [480],
            'precipitation_sum': ['lots'],
            'wind_speed_10m_max': [2.5],
          },
        }),
        '2025-07-12',
      );
      expect(odd?.tempMaxC, isNull, reason: 'out of range');
      expect(odd?.precipMm, isNull, reason: 'not a number');
      expect(odd?.windMs, 2.5);
      expect(OpenMeteo.parseDay('not json', '2025-07-12'), isNull);
    },
  );

  test('M2-5: a busy service or hidden place is not asked', () async {
    final session = await logAt('2026-11-01');
    var calls = 0;
    final filler = WeatherFiller(
      db,
      OpenMeteo(
        client: MockClient((request) async {
          calls++;
          return http.Response('busy', 429);
        }),
        clock: clock,
      ),
      clock: clock,
    );
    expect(await filler.fillMissing(userId: 'me'), 0);
    expect(
      await db.select(db.weatherSnapshots).get(),
      isEmpty,
      reason: 'retry',
    );

    await db.customStatement(
      'UPDATE sessions SET location_hidden = 1 WHERE id = ?',
      [session],
    );
    calls = 0;
    expect(await filler.fillMissing(userId: 'me'), 0);
    expect(calls, 0, reason: "a hidden session's place stays on the device");
  });
}
