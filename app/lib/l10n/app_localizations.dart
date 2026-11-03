import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nb.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nb'),
  ];

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabCv.
  ///
  /// In en, this message translates to:
  /// **'CV'**
  String get tabCv;

  /// No description provided for @tabTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get tabTraining;

  /// Label of the centre button in the tab bar and of empty-state actions.
  ///
  /// In en, this message translates to:
  /// **'Log a session'**
  String get logButton;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your sessions show up here'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log your first session and it appears in your feed. Friends\' sessions join it later.'**
  String get feedEmptyBody;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your history starts with one session'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Days out, grades, pyramids and insights fill in as you log.'**
  String get historyEmptyBody;

  /// No description provided for @cvTitle.
  ///
  /// In en, this message translates to:
  /// **'Climbing CV'**
  String get cvTitle;

  /// No description provided for @cvEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your CV builds itself'**
  String get cvEmptyTitle;

  /// No description provided for @cvEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every climb you log adds to your levels and experience, and shows what you have not tried yet.'**
  String get cvEmptyBody;

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainingTitle;

  /// No description provided for @trainingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track strength and mobility'**
  String get trainingEmptyTitle;

  /// No description provided for @trainingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finger strength, pulling, core and mobility tests arrive here, with your progress over time.'**
  String get trainingEmptyBody;

  /// No description provided for @logSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a session'**
  String get logSheetTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The link may be old or mistyped.'**
  String get notFoundBody;

  /// No description provided for @notFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Go to the feed'**
  String get notFoundAction;

  /// Tooltip of the search button on the History tab.
  ///
  /// In en, this message translates to:
  /// **'Find a route'**
  String get routeSearchOpen;

  /// No description provided for @routeSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a route'**
  String get routeSearchTitle;

  /// Label of the search field.
  ///
  /// In en, this message translates to:
  /// **'Route or crag'**
  String get routeSearchField;

  /// No description provided for @routeSearchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No routes match \"{term}\".'**
  String routeSearchNoMatch(String term);

  /// No description provided for @routeSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Routes you add and climb show up here.'**
  String get routeSearchEmpty;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This route is gone or private.'**
  String get routeNotFound;

  /// No description provided for @routeUngraded.
  ///
  /// In en, this message translates to:
  /// **'Ungraded'**
  String get routeUngraded;

  /// No description provided for @routeLength.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String routeLength(int metres);

  /// No description provided for @routePitches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pitch} other{{count} pitches}}'**
  String routePitches(int count);

  /// No description provided for @routeRopeLength.
  ///
  /// In en, this message translates to:
  /// **'{metres} m rope'**
  String routeRopeLength(int metres);

  /// No description provided for @routeDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get routeDetails;

  /// No description provided for @routeYourClimbs.
  ///
  /// In en, this message translates to:
  /// **'Your climbs'**
  String get routeYourClimbs;

  /// No description provided for @routeNotClimbed.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t logged this route yet.'**
  String get routeNotClimbed;

  /// No description provided for @routeLastClimbed.
  ///
  /// In en, this message translates to:
  /// **'Last climbed {date}'**
  String routeLastClimbed(String date);

  /// A route's discipline, by its stable key.
  ///
  /// In en, this message translates to:
  /// **'{discipline, select, sport{Sport} trad{Trad} boulder{Boulder} alpine{Alpine} ice{Ice} mixed{Mixed} aid{Aid} dws{Deep water solo} other{}}'**
  String discipline(String discipline);

  /// A climb's style, by its stable key.
  ///
  /// In en, this message translates to:
  /// **'{style, select, onsight{Onsight} flash{Flash} redpoint{Redpoint} repeat{Repeat} attempt{Attempt} other{}}'**
  String ascentStyle(String style);

  /// No description provided for @ascentTries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 try} other{{count} tries}}'**
  String ascentTries(int count);

  /// Which way a crag faces, by compass key.
  ///
  /// In en, this message translates to:
  /// **'{direction, select, N{Faces north} NE{Faces northeast} E{Faces east} SE{Faces southeast} S{Faces south} SW{Faces southwest} W{Faces west} NW{Faces northwest} other{}}'**
  String aspect(String direction);

  /// A route detail by its stable key, with the dot replaced by an underscore (hold.crimp is hold_crimp). Empty for unknown keys.
  ///
  /// In en, this message translates to:
  /// **'{value, select, rock_granite{Granite} rock_gneiss{Gneiss} rock_limestone{Limestone} rock_sandstone{Sandstone} rock_basalt{Basalt} rock_conglomerate{Conglomerate} rock_quartzite{Quartzite} rock_schist{Schist} rock_dolerite{Dolerite} angle_slab{Slab} angle_vertical{Vertical} angle_overhang{Overhang} angle_roof{Roof} feature_face{Face} feature_finger_crack{Finger crack} feature_hand_crack{Hand crack} feature_offwidth{Offwidth} feature_chimney{Chimney} feature_corner{Corner} feature_arete{Arête} feature_tufa{Tufa} feature_ice_pillar{Ice pillar} feature_ice_curtain{Ice curtain} feature_mixed_dry_tool{Dry tooling} hold_crimp{Crimps} hold_pocket{Pockets} hold_pinch{Pinches} hold_sloper{Slopers} hold_jug{Jugs} hold_undercling{Underclings} hold_sidepull{Sidepulls} protection_bolted{Bolted} protection_trad{Trad gear} protection_mixed{Mixed protection} protection_runout{Runout} protection_none{No protection} protection_pads{Pads} protection_ice_screws{Ice screws} descent_lower_off{Lower off} descent_rappel{Rappel} descent_walk_off{Walk off} descent_downclimb{Downclimb} descent_swim{Swim} feel_very_soft{Very soft} feel_soft{Soft} feel_fair{Fair} feel_hard{Hard} feel_very_hard{Very hard} tag_pumpy{Pumpy} tag_techy{Technical} tag_powerful{Powerful} tag_scary{Scary} tag_sustained{Sustained} tag_reachy{Reachy} tag_polished{Polished} tag_great_rock{Great rock} tag_heady{Heady} tag_balancy{Balancy} condition_perfect{Perfect} condition_dry{Dry} condition_humid{Humid} condition_damp{Damp} condition_wet{Wet} condition_icy{Icy} condition_windy{Windy} condition_cold{Cold} condition_hot{Hot} other{}}'**
  String attributeValue(String value);

  /// No description provided for @routeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a route'**
  String get routeAdd;

  /// No description provided for @routeFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New route'**
  String get routeFormTitle;

  /// No description provided for @formName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formName;

  /// No description provided for @routeFormNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give the route a name.'**
  String get routeFormNameMissing;

  /// No description provided for @routeFormCrag.
  ///
  /// In en, this message translates to:
  /// **'Crag'**
  String get routeFormCrag;

  /// No description provided for @routeFormCragMissing.
  ///
  /// In en, this message translates to:
  /// **'Pick the crag the route is in.'**
  String get routeFormCragMissing;

  /// No description provided for @routeFormRockFromCrag.
  ///
  /// In en, this message translates to:
  /// **'Rock type comes from the crag: {rock}.'**
  String routeFormRockFromCrag(String rock);

  /// No description provided for @routeFormDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get routeFormDiscipline;

  /// No description provided for @routeFormGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade ({system})'**
  String routeFormGrade(String system);

  /// No description provided for @routeFormNoGrade.
  ///
  /// In en, this message translates to:
  /// **'No grade yet'**
  String get routeFormNoGrade;

  /// No description provided for @routeFormLength.
  ///
  /// In en, this message translates to:
  /// **'Length in metres'**
  String get routeFormLength;

  /// No description provided for @routeFormPitches.
  ///
  /// In en, this message translates to:
  /// **'Pitches'**
  String get routeFormPitches;

  /// No description provided for @routeFormPitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch {number}'**
  String routeFormPitch(int number);

  /// No description provided for @formNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to {max}.'**
  String formNumberInvalid(int max);

  /// No description provided for @routeFormAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get routeFormAngle;

  /// No description provided for @routeFormFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get routeFormFeatures;

  /// No description provided for @routeFormHolds.
  ///
  /// In en, this message translates to:
  /// **'Holds'**
  String get routeFormHolds;

  /// No description provided for @routeFormProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get routeFormProtection;

  /// No description provided for @routeFormDescent.
  ///
  /// In en, this message translates to:
  /// **'Descent'**
  String get routeFormDescent;

  /// No description provided for @routeFormRope.
  ///
  /// In en, this message translates to:
  /// **'Rope needed'**
  String get routeFormRope;

  /// No description provided for @routeFormFirstAscent.
  ///
  /// In en, this message translates to:
  /// **'First ascent'**
  String get routeFormFirstAscent;

  /// No description provided for @routeFormFirstAscentHint.
  ///
  /// In en, this message translates to:
  /// **'Names and year'**
  String get routeFormFirstAscentHint;

  /// No description provided for @routeFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get routeFormSave;

  /// No description provided for @formSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check the fields and try again.'**
  String get formSaveFailed;

  /// No description provided for @cragAdd.
  ///
  /// In en, this message translates to:
  /// **'New crag'**
  String get cragAdd;

  /// No description provided for @cragFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New crag'**
  String get cragFormTitle;

  /// No description provided for @cragFormNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give the crag a name.'**
  String get cragFormNameMissing;

  /// No description provided for @cragFormCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get cragFormCountry;

  /// No description provided for @cragFormCountryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use two letters, such as NO.'**
  String get cragFormCountryInvalid;

  /// No description provided for @cragFormRock.
  ///
  /// In en, this message translates to:
  /// **'Rock type'**
  String get cragFormRock;

  /// No description provided for @cragFormLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get cragFormLatitude;

  /// No description provided for @cragFormLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get cragFormLongitude;

  /// No description provided for @cragFormLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees, such as 59.92 and 10.50. Leave both empty if you are not sure.'**
  String get cragFormLocationHint;

  /// No description provided for @cragFormLocationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter both, as decimal degrees.'**
  String get cragFormLocationInvalid;

  /// No description provided for @cragFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save crag'**
  String get cragFormSave;

  /// No description provided for @formLengthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a length in metres, up to {max}.'**
  String formLengthInvalid(int max);

  /// No description provided for @logWhere.
  ///
  /// In en, this message translates to:
  /// **'Where did you climb?'**
  String get logWhere;

  /// No description provided for @logOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get logOutdoor;

  /// No description provided for @logOutdoorHint.
  ///
  /// In en, this message translates to:
  /// **'Crags and mountains'**
  String get logOutdoorHint;

  /// No description provided for @logIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor gym'**
  String get logIndoor;

  /// No description provided for @logIndoorHint.
  ///
  /// In en, this message translates to:
  /// **'Walls and boards'**
  String get logIndoorHint;

  /// No description provided for @logIndoorSoon.
  ///
  /// In en, this message translates to:
  /// **'Gym climbs can be logged once gyms arrive. For now, log your outdoor climbs.'**
  String get logIndoorSoon;

  /// No description provided for @logRoute.
  ///
  /// In en, this message translates to:
  /// **'Route or problem'**
  String get logRoute;

  /// No description provided for @logChangeRoute.
  ///
  /// In en, this message translates to:
  /// **'Change route'**
  String get logChangeRoute;

  /// No description provided for @logStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get logStyle;

  /// No description provided for @logTries.
  ///
  /// In en, this message translates to:
  /// **'Tries'**
  String get logTries;

  /// No description provided for @logTriesFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer tries'**
  String get logTriesFewer;

  /// No description provided for @logTriesMore.
  ///
  /// In en, this message translates to:
  /// **'More tries'**
  String get logTriesMore;

  /// No description provided for @logHintSent.
  ///
  /// In en, this message translates to:
  /// **'You have sent this route, so it logs as a repeat or an attempt.'**
  String get logHintSent;

  /// No description provided for @logHintTried.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 earlier try on this route, so onsight and flash are not possible.} other{You have {count} earlier tries on this route, so onsight and flash are not possible.}}'**
  String logHintTried(int count);

  /// No description provided for @logHintBoulder.
  ///
  /// In en, this message translates to:
  /// **'Boulders are flashed, not onsighted.'**
  String get logHintBoulder;

  /// No description provided for @logRope.
  ///
  /// In en, this message translates to:
  /// **'Rope'**
  String get logRope;

  /// How a climb was climbed, by its stable key.
  ///
  /// In en, this message translates to:
  /// **'{type, select, lead{Lead} follow{Follow} toprope{Top rope} solo{Solo} boulder{Boulder} other{}}'**
  String ascentType(String type);

  /// No description provided for @logFeel.
  ///
  /// In en, this message translates to:
  /// **'How it felt for the grade'**
  String get logFeel;

  /// No description provided for @logPersonalGrade.
  ///
  /// In en, this message translates to:
  /// **'Your grade'**
  String get logPersonalGrade;

  /// No description provided for @logPersonalGradeNone.
  ///
  /// In en, this message translates to:
  /// **'Same as the route'**
  String get logPersonalGradeNone;

  /// No description provided for @logTags.
  ///
  /// In en, this message translates to:
  /// **'Describe it'**
  String get logTags;

  /// No description provided for @logQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get logQuality;

  /// No description provided for @logQualityLevel.
  ///
  /// In en, this message translates to:
  /// **'{level, select, q1{Good} q2{Great} q3{Classic} other{}}'**
  String logQualityLevel(String level);

  /// No description provided for @logAddClimb.
  ///
  /// In en, this message translates to:
  /// **'Add climb and log another'**
  String get logAddClimb;

  /// No description provided for @logClimbCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 climb} other{{count} climbs}}'**
  String logClimbCount(int count);

  /// No description provided for @logRemoveClimb.
  ///
  /// In en, this message translates to:
  /// **'Remove {route}'**
  String logRemoveClimb(String route);

  /// No description provided for @logSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get logSession;

  /// No description provided for @logDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get logDate;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get logTitle;

  /// No description provided for @logDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get logDescription;

  /// No description provided for @logConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get logConditions;

  /// No description provided for @logPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get logPartners;

  /// No description provided for @logPartnersHint.
  ///
  /// In en, this message translates to:
  /// **'Names, separated by commas'**
  String get logPartnersHint;

  /// No description provided for @logSave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save session} other{Save session ({count} climbs)}}'**
  String logSave(int count);

  /// No description provided for @logSaved.
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get logSaved;

  /// No description provided for @logClimbRejected.
  ///
  /// In en, this message translates to:
  /// **'Climb {number} no longer fits the style and tries rules. Check it and try again.'**
  String logClimbRejected(int number);

  /// No description provided for @logLaterClimbsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Later climbs on that route no longer fit the rules, so they were removed too.'**
  String get logLaterClimbsRemoved;

  /// No description provided for @routeYourGrade.
  ///
  /// In en, this message translates to:
  /// **'Your grade: {grade}'**
  String routeYourGrade(String grade);

  /// No description provided for @routeYourFeel.
  ///
  /// In en, this message translates to:
  /// **'How it felt: {feel}'**
  String routeYourFeel(String feel);

  /// On a climb in a route's history, when the route has been regraded since.
  ///
  /// In en, this message translates to:
  /// **'graded {grade} then'**
  String routeLoggedAt(String grade);

  /// No description provided for @cragFormMap.
  ///
  /// In en, this message translates to:
  /// **'Map. Tap to place the crag.'**
  String get cragFormMap;

  /// No description provided for @cragFormLocationHintMap.
  ///
  /// In en, this message translates to:
  /// **'Tap the map, or type decimal degrees such as 59.92 and 10.50. Leave both empty if you are not sure.'**
  String get cragFormLocationHintMap;

  /// A season by name (spring, summer, autumn, winter).
  ///
  /// In en, this message translates to:
  /// **'{season, select, spring{Spring} summer{Summer} autumn{Autumn} winter{Winter} other{}}'**
  String season(String season);

  /// No description provided for @weatherTemp.
  ///
  /// In en, this message translates to:
  /// **'{temp} °C'**
  String weatherTemp(String temp);

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'{mm} mm rain'**
  String weatherRain(String mm);

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'{speed} m/s wind'**
  String weatherWind(String speed);

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This session isn\'t on this phone. It may have been deleted.'**
  String get sessionNotFound;

  /// No description provided for @sessionWith.
  ///
  /// In en, this message translates to:
  /// **'With {names}'**
  String sessionWith(String names);

  /// No description provided for @sessionClimbs.
  ///
  /// In en, this message translates to:
  /// **'Climbs'**
  String get sessionClimbs;

  /// No description provided for @sessionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get sessionEdit;

  /// No description provided for @sessionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get sessionDelete;

  /// No description provided for @sessionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get sessionDeleteTitle;

  /// No description provided for @sessionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its climbs and partners are deleted with it. Later climbs on the same routes are recounted.'**
  String get sessionDeleteBody;

  /// No description provided for @sessionDeleteLastBody.
  ///
  /// In en, this message translates to:
  /// **'This is the session\'s last climb, so saving deletes the whole session.'**
  String get sessionDeleteLastBody;

  /// No description provided for @sessionDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sessionDeleteConfirm;

  /// No description provided for @sessionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get sessionKeep;

  /// No description provided for @sessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Session deleted'**
  String get sessionDeleted;

  /// No description provided for @logEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get logEditTitle;

  /// No description provided for @logEditExisting.
  ///
  /// In en, this message translates to:
  /// **'In this session'**
  String get logEditExisting;

  /// No description provided for @logEditForgotten.
  ///
  /// In en, this message translates to:
  /// **'Add a climb you forgot'**
  String get logEditForgotten;

  /// No description provided for @logEditMarked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 climb is removed when you save.} other{{count} climbs are removed when you save.}}'**
  String logEditMarked(int count);

  /// No description provided for @logEditKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep {route}'**
  String logEditKeep(String route);

  /// No description provided for @logEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get logEditSave;

  /// No description provided for @logEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get logEditSaved;

  /// No description provided for @logLaterClimbRejected.
  ///
  /// In en, this message translates to:
  /// **'A later climb on the same route depends on this one. Change or remove that climb first.'**
  String get logLaterClimbRejected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nb'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nb':
      return AppLocalizationsNb();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
