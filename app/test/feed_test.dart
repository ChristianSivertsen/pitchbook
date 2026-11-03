import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva_data/sva_data.dart';

void main() {
  testWidgets("M2-5: a session in the feed shows the day's weather", (
    tester,
  ) async {
    final session = Session(
      id: 's1',
      createdAt: DateTime.utc(2026, 11),
      updatedAt: DateTime.utc(2026, 11),
      ownerId: 'local',
      visibility: 'private',
      setting: 'outdoor',
      localDate: '2026-11-01',
      tz: 'Europe/Oslo',
      title: 'Kveld på Kolsås',
      locationHidden: false,
    );
    final weather = WeatherSnapshot(
      id: 'w1',
      createdAt: DateTime.utc(2026, 11),
      updatedAt: DateTime.utc(2026, 11),
      ownerId: 'local',
      visibility: 'private',
      sessionId: 's1',
      source: 'open_meteo',
      tempC: 10.1,
      precipMm: 0.4,
      windMs: 3.1,
      fetchedAt: DateTime.utc(2026, 11),
    );
    final container = ProviderContainer(
      overrides: [
        mySessionsProvider.overrideWith((ref) => Stream.value([session])),
        sessionAscentsProvider.overrideWith((ref, id) => Stream.value([])),
        sessionWeatherProvider.overrideWith((ref, id) => Stream.value(weather)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kveld på Kolsås'), findsOneWidget);
    expect(find.text('10 °C · 0.4 mm rain · 3 m/s wind'), findsOneWidget);
  });
}
