// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabHistory => 'Historikk';

  @override
  String get tabCv => 'CV';

  @override
  String get tabTraining => 'Trening';

  @override
  String get logButton => 'Logg en økt';

  @override
  String get feedEmptyTitle => 'Øktene dine dukker opp her';

  @override
  String get feedEmptyBody =>
      'Logg din første økt, så havner den i feeden din. Øktene til vennene dine kommer senere.';

  @override
  String get historyTitle => 'Historikk';

  @override
  String get historyEmptyTitle => 'Historikken din starter med én økt';

  @override
  String get historyEmptyBody =>
      'Dager ute, grader, pyramider og innsikt fylles ut etter hvert som du logger.';

  @override
  String get cvTitle => 'Klatre-CV';

  @override
  String get cvEmptyTitle => 'CV-en din bygger seg selv';

  @override
  String get cvEmptyBody =>
      'Hver rute du logger, bygger opp nivåene og erfaringen din og viser hva du ikke har prøvd ennå.';

  @override
  String get trainingTitle => 'Trening';

  @override
  String get trainingEmptyTitle => 'Hold oversikt over styrke og bevegelighet';

  @override
  String get trainingEmptyBody =>
      'Tester av fingerstyrke, trekkraft, core og bevegelighet havner her, med fremgangen din over tid.';

  @override
  String get logSheetTitle => 'Logg en økt';

  @override
  String get logSheetBody => 'Snart kan du logge klatring her.';

  @override
  String get close => 'Lukk';

  @override
  String get notFoundTitle => 'Denne siden finnes ikke';

  @override
  String get notFoundBody => 'Lenken kan være gammel eller feilskrevet.';

  @override
  String get notFoundAction => 'Gå til feeden';
}
