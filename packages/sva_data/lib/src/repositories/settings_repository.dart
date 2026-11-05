import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/repositories/repository.dart';

/// The app's themes by stable key: follow the phone, Midnight sun (dark)
/// or Daylight (light).
const themes = {'system', 'midnight', 'daylight'};

/// The languages the app has, by language code.
const languages = {'nb', 'en'};

/// The grade system each grade type shows in until the user picks one:
/// the ones the log sheet uses.
const defaultGradeSystems = {'free_route': 'nor', 'boulder': 'font'};

/// One user's preferences, as saved on their profile (docs/schema.md,
/// profiles).
final class Settings {
  const new({
    this.theme = 'system',
    this.language,
    this.defaultVisibility = 'private',
    this.gradeSystems = const {},
  });

  /// One of [themes].
  final String theme;

  /// One of [languages], or `null` to follow the phone.
  final String? language;

  /// The visibility new sessions get.
  final String defaultVisibility;

  /// The system chosen for each grade type, by system key.
  final Map<String, String> gradeSystems;

  /// The system grades of [gradeType] show in, or `null` when the type has
  /// neither a choice nor a default.
  String? gradeSystemFor(String gradeType) =>
      gradeSystems[gradeType] ?? defaultGradeSystems[gradeType];
}

/// Reads and saves a user's [Settings] on their profile row, which is
/// created on the first change. Values are checked here, at the boundary.
class SettingsRepository {
  new(this.db, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final SvaDatabase db;
  final DateTime Function() _clock;

  /// [userId]'s settings, live. Defaults until anything is saved.
  Stream<Settings> watch(String userId) {
    final query = db.select(db.profiles)
      ..where((p) => p.id.equals(userId) & p.deletedAt.isNull());
    return query.watchSingleOrNull().map(
      (profile) => profile == null
          ? const Settings()
          : Settings(
              theme: profile.theme,
              language: profile.language,
              defaultVisibility: profile.defaultVisibility,
              gradeSystems: _decodeGradePrefs(profile.gradePrefs),
            ),
    );
  }

  /// Throws [ArgumentError] unless [theme] is one of [themes].
  Future<void> setTheme(String userId, String theme) {
    if (!themes.contains(theme)) throw ArgumentError.value(theme, 'theme');
    return _save(userId, ProfilesCompanion(theme: Value(theme)));
  }

  /// `null` follows the phone. Throws [ArgumentError] for a language the
  /// app does not have.
  Future<void> setLanguage(String userId, String? language) {
    if (language != null && !languages.contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    return _save(userId, ProfilesCompanion(language: Value(language)));
  }

  /// Throws [ArgumentError] unless [visibility] is a known visibility.
  Future<void> setDefaultVisibility(String userId, String visibility) {
    checkVisibility(visibility);
    return _save(
      userId,
      ProfilesCompanion(defaultVisibility: Value(visibility)),
    );
  }

  /// Shows grades of [gradeType] in the system [systemKey] from now on.
  /// Throws [ArgumentError] unless that system exists and grades that type.
  Future<void> setGradeSystem(
    String userId,
    String gradeType,
    String systemKey,
  ) async {
    final system =
        await (db.select(db.gradeSystems)..where(
              (s) =>
                  s.key.equals(systemKey) &
                  s.gradeType.equals(gradeType) &
                  s.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (system == null) throw ArgumentError.value(systemKey, 'systemKey');
    await db.transaction(() async {
      final current = await _profile(userId);
      final prefs = {..._decodeGradePrefs(current?.gradePrefs)};
      prefs[gradeType] = systemKey;
      await _save(
        userId,
        ProfilesCompanion(gradePrefs: Value(jsonEncode(prefs))),
      );
    });
  }

  Future<Profile?> _profile(String userId) => (db.select(
    db.profiles,
  )..where((p) => p.id.equals(userId))).getSingleOrNull();

  /// Applies [changes] to [userId]'s profile, creating it with the
  /// defaults first if needed.
  Future<void> _save(String userId, ProfilesCompanion changes) =>
      db.transaction(() async {
        final now = _clock();
        if (await _profile(userId) == null) {
          await db
              .into(db.profiles)
              .insert(
                ProfilesCompanion.insert(
                  id: userId,
                  createdAt: now,
                  updatedAt: now,
                  defaultVisibility: const Settings().defaultVisibility,
                  rackVisibility: 'private',
                  theme: const Settings().theme,
                ),
              );
        }
        await (db.update(db.profiles)..where((p) => p.id.equals(userId))).write(
          changes.copyWith(updatedAt: Value(now)),
        );
      });

  /// The saved grade systems; anything unreadable counts as no choice.
  static Map<String, String> _decodeGradePrefs(String? json) {
    if (json == null) return const {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return const {};
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (key is String && value is String) key: value,
      };
    } on FormatException {
      return const {};
    }
  }
}
