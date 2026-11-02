import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;

  setUp(() async {
    db = SvaDatabase.inMemory();
    await GradeRepository(db).seed();
    await AttributeRepository(db).seed();
  });
  tearDown(() => db.close());

  test('M2-4: a climb keeps the official grade it was logged at and the '
      'personal grade', () async {
    final editor = RouteEditor(db);
    final crag = await editor.addCrag(
      const NewCrag(name: 'Kolsås', countryCode: 'NO'),
      userId: 'me',
    );
    final route = await editor.addRoute(
      NewRoute(
        areaId: crag,
        name: 'Hjemmebane',
        discipline: 'sport',
        gradeId: seedId('grade:nor:6'),
      ),
      userId: 'me',
    );
    await SessionLogger(db).logOutdoor(
      SessionDraft(
        localDate: '2026-11-01',
        tz: 'Europe/Oslo',
        visibility: 'private',
        climbs: [
          ClimbDraft(
            routeId: route,
            style: AscentStyle.onsight,
            tries: 1,
            ascentType: 'lead',
            feel: 'feel.hard',
            personalGradeId: seedId('grade:nor:6+'),
          ),
        ],
      ),
      userId: 'me',
    );

    // The route is regraded later; the climb keeps what it was logged at.
    await db.customStatement(
      'UPDATE route_grades SET grade_id = ? WHERE route_id = ?',
      [seedId('grade:nor:7'), route],
    );

    final climb = (await AscentRepository(
      db,
    ).watchOnRoute(route, userId: 'me').first).single;
    expect(climb.officialGrade, '6');
    expect(climb.personalGrade, '6+');
    expect(climb.ascent.feel, 'feel.hard');
    expect(climb.ascent.difficultyScore, isNotNull);
    expect((await RouteRepository(db).hit(route, userId: 'me'))?.grade, '7');
  });
}
