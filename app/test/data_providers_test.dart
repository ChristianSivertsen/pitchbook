import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva_data/sva_data.dart';

void main() {
  test('M1-5: providers stream repository data to screens', () async {
    final db = SvaDatabase.inMemory();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final seen = <List<Session>>[];
    container.listen(
      mySessionsProvider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await container
        .read(sessionRepositoryProvider)
        .create(
          const SessionsCompanion(
            setting: Value('indoor'),
            localDate: Value('2026-10-29'),
            tz: Value('Europe/Oslo'),
            visibility: Value('friends'),
          ),
          userId: container.read(currentUserIdProvider),
        );
    await pumpEventQueue();
    expect(seen.last.single.localDate, '2026-10-29');
  });
}
