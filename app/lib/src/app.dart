import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/theme_mode.dart';
import 'package:sva_ui/sva_ui.dart';

/// Picks the app language from the phone's languages. Norwegian phones set
/// to Bokmål, Nynorsk or plain Norwegian get Bokmål until Nynorsk exists;
/// anything unsupported falls back to English.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  if (device == null) return const Locale('en');
  if (const {'nb', 'nn', 'no'}.contains(device.languageCode)) {
    return const Locale('nb');
  }
  return supported.firstWhere(
    (locale) => locale.languageCode == device.languageCode,
    orElse: () => const Locale('en'),
  );
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
      localeResolutionCallback: resolveLocale,
    );
  }
}
