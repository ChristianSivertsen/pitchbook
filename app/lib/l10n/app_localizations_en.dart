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
  String get close => 'Close';

  @override
  String get notFoundTitle => 'This page doesn\'t exist';

  @override
  String get notFoundBody => 'The link may be old or mistyped.';

  @override
  String get notFoundAction => 'Go to the feed';

  @override
  String get routeSearchOpen => 'Find a route';

  @override
  String get routeSearchTitle => 'Find a route';

  @override
  String get routeSearchField => 'Route or crag';

  @override
  String routeSearchNoMatch(String term) {
    return 'No routes match \"$term\".';
  }

  @override
  String get routeSearchEmpty => 'Routes you add and climb show up here.';

  @override
  String get routeNotFound => 'This route is gone or private.';

  @override
  String get routeUngraded => 'Ungraded';

  @override
  String routeLength(int metres) {
    return '$metres m';
  }

  @override
  String routePitches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pitches',
      one: '1 pitch',
    );
    return '$_temp0';
  }

  @override
  String routeRopeLength(int metres) {
    return '$metres m rope';
  }

  @override
  String get routeDetails => 'Details';

  @override
  String get routeYourClimbs => 'Your climbs';

  @override
  String get routeNotClimbed => 'You haven\'t logged this route yet.';

  @override
  String routeLastClimbed(String date) {
    return 'Last climbed $date';
  }

  @override
  String discipline(String discipline) {
    String _temp0 = intl.Intl.selectLogic(discipline, {
      'sport': 'Sport',
      'trad': 'Trad',
      'boulder': 'Boulder',
      'alpine': 'Alpine',
      'ice': 'Ice',
      'mixed': 'Mixed',
      'aid': 'Aid',
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
      'repeat': 'Repeat',
      'attempt': 'Attempt',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String ascentTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries',
      one: '1 try',
    );
    return '$_temp0';
  }

  @override
  String aspect(String direction) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'N': 'Faces north',
      'NE': 'Faces northeast',
      'E': 'Faces east',
      'SE': 'Faces southeast',
      'S': 'Faces south',
      'SW': 'Faces southwest',
      'W': 'Faces west',
      'NW': 'Faces northwest',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String attributeValue(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'rock_granite': 'Granite',
      'rock_gneiss': 'Gneiss',
      'rock_limestone': 'Limestone',
      'rock_sandstone': 'Sandstone',
      'rock_basalt': 'Basalt',
      'rock_conglomerate': 'Conglomerate',
      'rock_quartzite': 'Quartzite',
      'rock_schist': 'Schist',
      'rock_dolerite': 'Dolerite',
      'angle_slab': 'Slab',
      'angle_vertical': 'Vertical',
      'angle_overhang': 'Overhang',
      'angle_roof': 'Roof',
      'feature_face': 'Face',
      'feature_finger_crack': 'Finger crack',
      'feature_hand_crack': 'Hand crack',
      'feature_offwidth': 'Offwidth',
      'feature_chimney': 'Chimney',
      'feature_corner': 'Corner',
      'feature_arete': 'Arête',
      'feature_tufa': 'Tufa',
      'feature_ice_pillar': 'Ice pillar',
      'feature_ice_curtain': 'Ice curtain',
      'feature_mixed_dry_tool': 'Dry tooling',
      'hold_crimp': 'Crimps',
      'hold_pocket': 'Pockets',
      'hold_pinch': 'Pinches',
      'hold_sloper': 'Slopers',
      'hold_jug': 'Jugs',
      'hold_undercling': 'Underclings',
      'hold_sidepull': 'Sidepulls',
      'protection_bolted': 'Bolted',
      'protection_trad': 'Trad gear',
      'protection_mixed': 'Mixed protection',
      'protection_runout': 'Runout',
      'protection_none': 'No protection',
      'protection_pads': 'Pads',
      'protection_ice_screws': 'Ice screws',
      'descent_lower_off': 'Lower off',
      'descent_rappel': 'Rappel',
      'descent_walk_off': 'Walk off',
      'descent_downclimb': 'Downclimb',
      'descent_swim': 'Swim',
      'feel_very_soft': 'Very soft',
      'feel_soft': 'Soft',
      'feel_fair': 'Fair',
      'feel_hard': 'Hard',
      'feel_very_hard': 'Very hard',
      'tag_pumpy': 'Pumpy',
      'tag_techy': 'Technical',
      'tag_powerful': 'Powerful',
      'tag_scary': 'Scary',
      'tag_sustained': 'Sustained',
      'tag_reachy': 'Reachy',
      'tag_polished': 'Polished',
      'tag_great_rock': 'Great rock',
      'tag_heady': 'Heady',
      'tag_balancy': 'Balancy',
      'condition_perfect': 'Perfect',
      'condition_dry': 'Dry',
      'condition_humid': 'Humid',
      'condition_damp': 'Damp',
      'condition_wet': 'Wet',
      'condition_icy': 'Icy',
      'condition_windy': 'Windy',
      'condition_cold': 'Cold',
      'condition_hot': 'Hot',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routeAdd => 'Add a route';

  @override
  String get routeFormTitle => 'New route';

  @override
  String get formName => 'Name';

  @override
  String get routeFormNameMissing => 'Give the route a name.';

  @override
  String get routeFormCrag => 'Crag';

  @override
  String get routeFormCragMissing => 'Pick the crag the route is in.';

  @override
  String routeFormRockFromCrag(String rock) {
    return 'Rock type comes from the crag: $rock.';
  }

  @override
  String get routeFormDiscipline => 'Discipline';

  @override
  String routeFormGrade(String system) {
    return 'Grade ($system)';
  }

  @override
  String get routeFormNoGrade => 'No grade yet';

  @override
  String get routeFormLength => 'Length in metres';

  @override
  String get routeFormPitches => 'Pitches';

  @override
  String routeFormPitch(int number) {
    return 'Pitch $number';
  }

  @override
  String formNumberInvalid(int max) {
    return 'Enter a number from 1 to $max.';
  }

  @override
  String get routeFormAngle => 'Angle';

  @override
  String get routeFormFeatures => 'Features';

  @override
  String get routeFormHolds => 'Holds';

  @override
  String get routeFormProtection => 'Protection';

  @override
  String get routeFormDescent => 'Descent';

  @override
  String get routeFormRope => 'Rope needed';

  @override
  String get routeFormFirstAscent => 'First ascent';

  @override
  String get routeFormFirstAscentHint => 'Names and year';

  @override
  String get routeFormSave => 'Save route';

  @override
  String get formSaveFailed =>
      'Couldn\'t save. Check the fields and try again.';

  @override
  String get cragAdd => 'New crag';

  @override
  String get cragFormTitle => 'New crag';

  @override
  String get cragFormNameMissing => 'Give the crag a name.';

  @override
  String get cragFormCountry => 'Country code';

  @override
  String get cragFormCountryInvalid => 'Use two letters, such as NO.';

  @override
  String get cragFormRock => 'Rock type';

  @override
  String get cragFormLatitude => 'Latitude';

  @override
  String get cragFormLongitude => 'Longitude';

  @override
  String get cragFormLocationHint =>
      'Decimal degrees, such as 59.92 and 10.50. Leave both empty if you are not sure.';

  @override
  String get cragFormLocationInvalid => 'Enter both, as decimal degrees.';

  @override
  String get cragFormSave => 'Save crag';

  @override
  String formLengthInvalid(int max) {
    return 'Enter a length in metres, up to $max.';
  }

  @override
  String get logWhere => 'Where did you climb?';

  @override
  String get logOutdoor => 'Outdoor';

  @override
  String get logOutdoorHint => 'Crags and mountains';

  @override
  String get logIndoor => 'Indoor gym';

  @override
  String get logIndoorHint => 'Walls and boards';

  @override
  String get logIndoorSoon =>
      'Gym climbs can be logged once gyms arrive. For now, log your outdoor climbs.';

  @override
  String get logRoute => 'Route or problem';

  @override
  String get logChangeRoute => 'Change route';

  @override
  String get logStyle => 'Style';

  @override
  String get logTries => 'Tries';

  @override
  String get logTriesFewer => 'Fewer tries';

  @override
  String get logTriesMore => 'More tries';

  @override
  String get logHintSent =>
      'You have sent this route, so it logs as a repeat or an attempt.';

  @override
  String logHintTried(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $count earlier tries on this route, so onsight and flash are not possible.',
      one: 'You have 1 earlier try on this route, so onsight and flash are not possible.',
    );
    return '$_temp0';
  }

  @override
  String get logHintBoulder => 'Boulders are flashed, not onsighted.';

  @override
  String get logRope => 'Rope';

  @override
  String ascentType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'lead': 'Lead',
      'follow': 'Follow',
      'toprope': 'Top rope',
      'solo': 'Solo',
      'boulder': 'Boulder',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get logFeel => 'How it felt for the grade';

  @override
  String get logPersonalGrade => 'Your grade';

  @override
  String get logPersonalGradeNone => 'Same as the route';

  @override
  String get logTags => 'Describe it';

  @override
  String get logQuality => 'Quality';

  @override
  String logQualityLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'q1': 'Good',
      'q2': 'Great',
      'q3': 'Classic',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get logAddClimb => 'Add climb and log another';

  @override
  String logClimbCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count climbs',
      one: '1 climb',
    );
    return '$_temp0';
  }

  @override
  String logRemoveClimb(String route) {
    return 'Remove $route';
  }

  @override
  String get logSession => 'Session';

  @override
  String get logDate => 'Date';

  @override
  String get logTitle => 'Title';

  @override
  String get logDescription => 'Description';

  @override
  String get logConditions => 'Conditions';

  @override
  String get logPartners => 'Partners';

  @override
  String get logPartnersHint => 'Names, separated by commas';

  @override
  String logSave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save session ($count climbs)',
      one: 'Save session',
    );
    return '$_temp0';
  }

  @override
  String get logSaved => 'Session saved';

  @override
  String logClimbRejected(int number) {
    return 'Climb $number no longer fits the style and tries rules. Check it and try again.';
  }

  @override
  String get logLaterClimbsRemoved =>
      'Later climbs on that route no longer fit the rules, so they were removed too.';

  @override
  String routeYourGrade(String grade) {
    return 'Your grade: $grade';
  }

  @override
  String routeYourFeel(String feel) {
    return 'How it felt: $feel';
  }

  @override
  String routeLoggedAt(String grade) {
    return 'graded $grade then';
  }

  @override
  String get cragFormMap => 'Map. Tap to place the crag.';

  @override
  String get cragFormLocationHintMap =>
      'Tap the map, or type decimal degrees such as 59.92 and 10.50. Leave both empty if you are not sure.';

  @override
  String get sessionNotFound =>
      'This session isn\'t on this phone. It may have been deleted.';

  @override
  String sessionWith(String names) {
    return 'With $names';
  }

  @override
  String get sessionClimbs => 'Climbs';

  @override
  String get sessionEdit => 'Edit session';

  @override
  String get sessionDelete => 'Delete session';

  @override
  String get sessionDeleteTitle => 'Delete this session?';

  @override
  String get sessionDeleteBody =>
      'Its climbs and partners are deleted with it. Later climbs on the same routes are recounted.';

  @override
  String get sessionDeleteLastBody =>
      'This is the session\'s last climb, so saving deletes the whole session.';

  @override
  String get sessionDeleteConfirm => 'Delete';

  @override
  String get sessionKeep => 'Keep';

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get logEditTitle => 'Edit session';

  @override
  String get logEditExisting => 'In this session';

  @override
  String get logEditForgotten => 'Add a climb you forgot';

  @override
  String logEditMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count climbs are removed when you save.',
      one: '1 climb is removed when you save.',
    );
    return '$_temp0';
  }

  @override
  String logEditKeep(String route) {
    return 'Keep $route';
  }

  @override
  String get logEditSave => 'Save changes';

  @override
  String get logEditSaved => 'Changes saved';

  @override
  String get logLaterClimbRejected =>
      'A later climb on the same route depends on this one. Change or remove that climb first.';
}
