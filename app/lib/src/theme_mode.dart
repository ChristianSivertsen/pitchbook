import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/src/data/providers.dart';

/// Which theme the app uses: follow the system (the default), or the user's
/// choice of Midnight sun (dark) or Daylight (light), from settings.
final Provider<ThemeMode> themeModeProvider = Provider(
  (ref) => switch (ref.watch(settingsProvider).value?.theme) {
    'midnight' => ThemeMode.dark,
    'daylight' => ThemeMode.light,
    _ => ThemeMode.system,
  },
);

/// The language the user chose in settings, or `null` to follow the phone.
final Provider<Locale?> appLocaleProvider = Provider(
  (ref) => switch (ref.watch(settingsProvider).value?.language) {
    final code? => Locale(code),
    null => null,
  },
);
