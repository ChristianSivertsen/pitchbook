import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sva_data/src/repositories/place_repositories.dart' show LatLon;

/// One day's weather at a place, as Open-Meteo reports it. Each value is
/// `null` when missing or out of a believable range.
typedef WeatherDay = ({
  double? tempMaxC,
  double? tempMinC,
  double? precipMm,
  double? windMs,

  /// The daily part of the answer, kept as it came.
  String raw,
});

/// Thrown when Open-Meteo is busy or failing (429 or 5xx): try later.
class WeatherUnavailable implements Exception {
  new(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'WeatherUnavailable: $statusCode';
}

/// How long to wait for an answer before trying again later.
const _timeout = Duration(seconds: 15);

/// Days back that the forecast API still covers; older days come from
/// the historical archive, which lags a few days behind.
const _forecastDaysBack = 60;

/// Reads a day's weather from Open-Meteo (open-meteo.com): the forecast
/// API for recent days, the archive for older ones. Free for
/// non-commercial use within 10,000 calls a day (docs/PLAN.md). Moves
/// behind an Edge Function in M11, so all clients share it.
///
/// Only the place and the day are sent, with the place rounded to about
/// 1 km: nothing about the user.
class OpenMeteo {
  new({http.Client? client, DateTime Function()? clock})
    : _client = client ?? http.Client(),
      _clock = clock ?? (() => DateTime.now().toUtc());

  final http.Client _client;
  final DateTime Function() _clock;

  /// The weather on [localDate] (`YYYY-MM-DD`) at [at], or `null` when
  /// Open-Meteo has none for that day and asking again will not help.
  /// Throws when it is worth trying again later: [http.ClientException]
  /// or a socket error without a connection, a [TimeoutException], or
  /// [WeatherUnavailable] when the service is busy or failing.
  Future<WeatherDay?> day(LatLon at, String localDate) async {
    final day = DateTime.parse(localDate);
    final today = _clock();
    final recent = today.difference(day).inDays <= _forecastDaysBack;
    final uri = Uri.https(
      recent ? 'api.open-meteo.com' : 'archive-api.open-meteo.com',
      recent ? '/v1/forecast' : '/v1/archive',
      {
        'latitude': at.lat.toStringAsFixed(2),
        'longitude': at.lon.toStringAsFixed(2),
        'start_date': localDate,
        'end_date': localDate,
        'daily':
            'temperature_2m_max,temperature_2m_min,'
            'precipitation_sum,wind_speed_10m_max',
        'wind_speed_unit': 'ms',
        'timezone': 'auto',
      },
    );
    final response = await _client.get(uri).timeout(_timeout);
    final status = response.statusCode;
    if (status == 429 || status >= 500) throw WeatherUnavailable(status);
    if (status != 200) return null;
    return parseDay(response.body, localDate);
  }

  /// Reads the day out of an Open-Meteo answer, checking every value at
  /// this boundary. `null` when the answer is not for [localDate].
  static WeatherDay? parseDay(String body, String localDate) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final daily = json['daily'];
    if (daily is! Map<String, Object?>) return null;
    final times = daily['time'];
    if (times is! List || times.length != 1 || times.first != localDate) {
      return null;
    }
    double? value(String key, double min, double max) {
      final list = daily[key];
      if (list is! List || list.length != 1) return null;
      final v = list.first;
      if (v is! num || v < min || v > max) return null;
      return v.toDouble();
    }

    return (
      tempMaxC: value('temperature_2m_max', -90, 60),
      tempMinC: value('temperature_2m_min', -90, 60),
      precipMm: value('precipitation_sum', 0, 2000),
      windMs: value('wind_speed_10m_max', 0, 120),
      raw: jsonEncode(daily),
    );
  }
}
