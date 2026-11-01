// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabHistory => 'History';

  @override
  String get tabCv => 'CV';

  @override
  String get tabTraining => 'Training';

  @override
  String get logButton => 'Log a session';

  @override
  String get feedEmptyTitle => 'Your sessions show up here';

  @override
  String get feedEmptyBody =>
      'Log your first session and it appears in your feed. Friends\' sessions join it later.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'Your history starts with one session';

  @override
  String get historyEmptyBody =>
      'Days out, grades, pyramids and insights fill in as you log.';

  @override
  String get cvTitle => 'Climbing CV';

  @override
  String get cvEmptyTitle => 'Your CV builds itself';

  @override
  String get cvEmptyBody =>
      'Every climb you log adds to your levels and experience, and shows what you have not tried yet.';

  @override
  String get trainingTitle => 'Training';

  @override
  String get trainingEmptyTitle => 'Track strength and mobility';

  @override
  String get trainingEmptyBody =>
      'Finger strength, pulling, core and mobility tests arrive here, with your progress over time.';

  @override
  String get logSheetTitle => 'Log a session';

  @override
  String get logSheetBody => 'Logging climbs is coming soon.';

  @override
  String get close => 'Close';

  @override
  String get notFoundTitle => 'This page doesn\'t exist';

  @override
  String get notFoundBody => 'The link may be old or mistyped.';

  @override
  String get notFoundAction => 'Go to the feed';
}
