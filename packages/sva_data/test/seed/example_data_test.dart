import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  test(
    'M1-5: example data loads once, follows the rules and removes',
    () async {
      final db = SvaDatabase.inMemory();
      addTearDown(db.close);
      await seedExampleData(db, userId: 'me');
      await seedExampleData(
        db,
        userId: 'me',
      ); // nothing changes the second time

      final sessions = await SessionRepository(db)
          .watchMine(userId: 'me')
          .first;
      expect(sessions, hasLength(4));
      expect(sessions.first.title, 'Last warm evening');
      final ascents = AscentRepository(db);
      final routes = await db.select(db.routes).get();
      for (final route in routes) {
        final log = await ascents.routeLog(route.id, userId: 'me');
        expect(checkRouteLog(log), everyElement(isEmpty), reason: route.name);
      }
      expect(
        await GearPieceRepository(db).watchMine(userId: 'me').first,
        hasLength(3),
      );
      expect(
        await GoalRepository(db).watchMine(userId: 'me').first,
        hasLength(1),
      );

      final all = <String>[
        for (final table in db.allTables)
          for (final row
              in await db
                  .customSelect('SELECT id FROM ${table.actualTableName}')
                  .get())
            row.read<String>('id'),
      ];
      expect(all.toSet(), exampleIds('me'), reason: 'every row is listed');

      await seedExampleData(db, userId: 'them');
      await removeExampleData(db, userId: 'me');
      expect(
        await SessionRepository(db).watchMine(userId: 'me').first,
        isEmpty,
      );
      expect(
        (await RouteRepository(
          db,
        ).search('', userId: 'me')).map((r) => r.createdBy),
        everyElement('them'),
        reason: "another user's example rows stay",
      );
    },
  );
}
