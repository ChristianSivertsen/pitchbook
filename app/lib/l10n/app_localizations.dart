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
  /// **'Every climb you log adds to your levels, experience and the gaps you have not tried yet.'**
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
  /// **'Logging climbs comes in the next milestone.'**
  String get logSheetBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
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
