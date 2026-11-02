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

  /// No description provided for @logSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Logging climbs is coming soon.'**
  String get logSheetBody;

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
  /// **'{value, select, rock_granite{Granite} rock_gneiss{Gneiss} rock_limestone{Limestone} rock_sandstone{Sandstone} rock_basalt{Basalt} rock_conglomerate{Conglomerate} rock_quartzite{Quartzite} rock_schist{Schist} rock_dolerite{Dolerite} angle_slab{Slab} angle_vertical{Vertical} angle_overhang{Overhang} angle_roof{Roof} feature_face{Face} feature_finger_crack{Finger crack} feature_hand_crack{Hand crack} feature_offwidth{Offwidth} feature_chimney{Chimney} feature_corner{Corner} feature_arete{Arête} feature_tufa{Tufa} feature_ice_pillar{Ice pillar} feature_ice_curtain{Ice curtain} feature_mixed_dry_tool{Dry tooling} hold_crimp{Crimps} hold_pocket{Pockets} hold_pinch{Pinches} hold_sloper{Slopers} hold_jug{Jugs} hold_undercling{Underclings} hold_sidepull{Sidepulls} protection_bolted{Bolted} protection_trad{Trad gear} protection_mixed{Mixed protection} protection_runout{Runout} protection_none{No protection} protection_pads{Pads} protection_ice_screws{Ice screws} descent_lower_off{Lower off} descent_rappel{Rappel} descent_walk_off{Walk off} descent_downclimb{Downclimb} descent_swim{Swim} other{}}'**
  String attributeValue(String value);
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
