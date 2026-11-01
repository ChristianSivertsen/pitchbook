import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/theme_mode.dart';
import 'package:sva_ui/sva_ui.dart';

/// Picks the app language from the phone's preferred languages, in order.
/// Norwegian (Bokmål, Nynorsk or plain Norwegian) gets Bokmål until Nynorsk
/// exists; if none of the phone's languages is supported, English.
Locale resolveLocale(List<Locale>? device, Iterable<Locale> supported) {
  for (final locale in device ?? const <Locale>[]) {
    if (const {'nb', 'nn', 'no'}.contains(locale.languageCode)) {
      return const Locale('nb');
    }
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
  }
  return const Locale('en');
}

/// Root widget: the Sva themes, following the system or the user's choice.
class SvaApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sva',
      theme: SvaTheme.daylight(),
      darkTheme: SvaTheme.midnight(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveLocale,
    );
  }
}
