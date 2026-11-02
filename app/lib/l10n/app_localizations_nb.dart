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

  @override
  String get routeSearchOpen => 'Finn en rute';

  @override
  String get routeSearchTitle => 'Finn en rute';

  @override
  String get routeSearchField => 'Rute eller felt';

  @override
  String routeSearchNoMatch(String term) {
    return 'Ingen ruter passer til «$term».';
  }

  @override
  String get routeSearchEmpty =>
      'Ruter du legger til og klatrer, dukker opp her.';

  @override
  String get routeNotFound => 'Ruten finnes ikke, eller den er privat.';

  @override
  String get routeUngraded => 'Ugradert';

  @override
  String routeLength(int metres) {
    return '$metres m';
  }

  @override
  String routePitches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taulengder',
      one: '1 taulengde',
    );
    return '$_temp0';
  }

  @override
  String routeRopeLength(int metres) {
    return '$metres m tau';
  }

  @override
  String get routeDetails => 'Detaljer';

  @override
  String get routeYourClimbs => 'Dine klatringer';

  @override
  String get routeNotClimbed => 'Du har ikke logget denne ruten ennå.';

  @override
  String routeLastClimbed(String date) {
    return 'Sist klatret $date';
  }

  @override
  String discipline(String discipline) {
    String _temp0 = intl.Intl.selectLogic(discipline, {
      'sport': 'Sport',
      'trad': 'Trad',
      'boulder': 'Buldring',
      'alpine': 'Alpint',
      'ice': 'Is',
      'mixed': 'Mix',
      'aid': 'Teknisk',
      'dws': 'Deep water solo',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String ascentStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'onsight': 'Onsight',
      'flash': 'Flash',
      'redpoint': 'Redpoint',
      'repeat': 'Repetisjon',
      'attempt': 'Forsøk',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String ascentTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forsøk',
      one: '1 forsøk',
    );
    return '$_temp0';
  }

  @override
  String aspect(String direction) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'N': 'Vender mot nord',
      'NE': 'Vender mot nordøst',
      'E': 'Vender mot øst',
      'SE': 'Vender mot sørøst',
      'S': 'Vender mot sør',
      'SW': 'Vender mot sørvest',
      'W': 'Vender mot vest',
      'NW': 'Vender mot nordvest',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String attributeValue(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'rock_granite': 'Granitt',
      'rock_gneiss': 'Gneis',
      'rock_limestone': 'Kalkstein',
      'rock_sandstone': 'Sandstein',
      'rock_basalt': 'Basalt',
      'rock_conglomerate': 'Konglomerat',
      'rock_quartzite': 'Kvartsitt',
      'rock_schist': 'Skifer',
      'rock_dolerite': 'Doleritt',
      'angle_slab': 'Plate',
      'angle_vertical': 'Loddrett',
      'angle_overhang': 'Overheng',
      'angle_roof': 'Tak',
      'feature_face': 'Vegg',
      'feature_finger_crack': 'Fingerriss',
      'feature_hand_crack': 'Håndriss',
      'feature_offwidth': 'Offwidth',
      'feature_chimney': 'Kamin',
      'feature_corner': 'Hjørne',
      'feature_arete': 'Egg',
      'feature_tufa': 'Tufa',
      'feature_ice_pillar': 'Issøyle',
      'feature_ice_curtain': 'Isgardin',
      'feature_mixed_dry_tool': 'Drytooling',
      'hold_crimp': 'Lister',
      'hold_pocket': 'Hull',
      'hold_pinch': 'Klyper',
      'hold_sloper': 'Slopere',
      'hold_jug': 'Bøtter',
      'hold_undercling': 'Undertak',
      'hold_sidepull': 'Sidetak',
      'protection_bolted': 'Boltet',
      'protection_trad': 'Naturlig sikret',
      'protection_mixed': 'Blandet sikring',
      'protection_runout': 'Glissent sikret',
      'protection_none': 'Usikret',
      'protection_pads': 'Crashpads',
      'protection_ice_screws': 'Isskruer',
      'descent_lower_off': 'Fire ned',
      'descent_rappel': 'Rappell',
      'descent_walk_off': 'Gå ned',
      'descent_downclimb': 'Klatre ned',
      'descent_swim': 'Svømme',
      'other': '',
    });
    return '$_temp0';
  }
}
