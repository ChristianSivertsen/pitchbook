import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which theme the app uses: follow the system (the default), or the user's
/// choice of Midnight sun (dark) or Daylight (light).
///
/// The settings screen sets this. The choice is kept for the running app;
/// saving it between launches comes with local storage (M1-5).
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Holds the current [ThemeMode].
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Use [value] from now on.
  // A setter would read as a field; this is an action the settings screen
  // takes, so it stays a method.
  // ignore: use_setters_to_change_properties
  void select(ThemeMode value) => state = value;
}
