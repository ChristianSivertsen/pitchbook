import 'package:flutter/material.dart';

import 'package:sva_ui/src/theme/sva_colors.dart';
import 'package:sva_ui/src/theme/sva_tokens.dart';
import 'package:sva_ui/src/theme/sva_typography.dart';

/// Builds the app's two themes from the Sva tokens.
abstract final class SvaTheme {
  /// Midnight sun, the dark theme and default.
  static ThemeData midnight() => _build(SvaColors.midnight, Brightness.dark);

  /// Daylight, the light theme.
  static ThemeData daylight() => _build(SvaColors.daylight, Brightness.light);

  static ThemeData _build(SvaColors colors, Brightness brightness) {
    final type = SvaTypography.withColor(colors.text);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.sun,
      onPrimary: colors.onSun,
      secondary: colors.granite,
      onSecondary: colors.onStyle,
      tertiary: colors.sea,
      onTertiary: colors.onStyle,
      error: colors.danger,
      onError: colors.onStyle,
      surface: colors.background,
      onSurface: colors.text,
      onSurfaceVariant: colors.textMuted,
      surfaceContainerLowest: colors.surfaceSunk,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surface,
      surfaceContainerHighest: colors.surface,
      outline: colors.line,
      outlineVariant: colors.line,
    );
    final textTheme = TextTheme(
      displaySmall: type.display,
      headlineSmall: type.title,
      titleMedium: type.headline,
      bodyMedium: type.body,
      bodyLarge: type.body,
      labelLarge: type.label,
      labelMedium: type.label,
      bodySmall: type.caption,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: SvaTypography.sansFamily,
      fontFamilyFallback: const [SvaTypography.sansFamily],
      textTheme: textTheme,
      dividerColor: colors.line,
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(SvaRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.sun,
          foregroundColor: colors.onSun,
          textStyle: type.label,
          minimumSize: const Size(0, SvaSpace.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(SvaRadius.card),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.line),
          textStyle: type.label,
          minimumSize: const Size(0, SvaSpace.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(SvaRadius.card),
          ),
        ),
      ),
      extensions: [colors, type],
    );
  }
}

/// Shortcuts for reading the Sva tokens from a widget.
extension SvaThemeContext on BuildContext {
  /// The current theme's colour tokens.
  SvaColors get svaColors => Theme.of(this).extension<SvaColors>()!;

  /// The current theme's text styles.
  SvaTypography get svaText => Theme.of(this).extension<SvaTypography>()!;
}
