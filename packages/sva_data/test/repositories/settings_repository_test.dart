import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;

  setUp(() async {
    db = SvaDatabase.inMemory();
    await GradeRepository(db).seed();
  });
  tearDown(() => db.close());

  test('M2-8: the settings repository saves and restores each value', () async {
    final settings = SettingsRepository(db);
    final fresh = await settings.watch('me').first;
    expect(fresh.theme, 'system');
    expect(fresh.language, isNull);
    expect(fresh.defaultVisibility, 'private');
    expect(fresh.gradeSystemFor('free_route'), 'nor');
    expect(fresh.gradeSystemFor('boulder'), 'font');

    await settings.setTheme('me', 'midnight');
    await settings.setLanguage('me', 'en');
    await settings.setDefaultVisibility('me', 'friends');
    await settings.setGradeSystem('me', 'free_route', 'french');
    await settings.setGradeSystem('me', 'boulder', 'v');

    // A new repository reads what the last run saved, as after a restart.
    final restored = await SettingsRepository(db).watch('me').first;
    expect(restored.theme, 'midnight');
    expect(restored.language, 'en');
    expect(restored.defaultVisibility, 'friends');
    expect(restored.gradeSystemFor('free_route'), 'french');
    expect(restored.gradeSystemFor('boulder'), 'v');
    expect(
      await SettingsRepository(db).watch('someone else').first,
      isA<Settings>().having((s) => s.theme, 'theme', 'system'),
    );

    // Back to following the phone.
    await settings.setLanguage('me', null);
    expect((await settings.watch('me').first).language, isNull);

    expect(() => settings.setTheme('me', 'neon'), throwsArgumentError);
    expect(() => settings.setLanguage('me', 'sv'), throwsArgumentError);
    expect(
      () => settings.setDefaultVisibility('me', 'everyone'),
      throwsArgumentError,
    );
    expect(
      () => settings.setGradeSystem('me', 'boulder', 'nor'),
      throwsArgumentError,
      reason: 'Norwegian grades routes, not boulders',
    );
    expect(
      () => settings.setGradeSystem('me', 'free_route', 'nope'),
      throwsArgumentError,
    );
  });
}
