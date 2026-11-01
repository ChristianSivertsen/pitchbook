import 'package:flutter/material.dart';

/// Sva colour tokens, one set per theme. Values come from docs/DESIGN.md.
///
/// Screens read these through `context.svaColors` and never use raw colours.
@immutable
class SvaColors extends ThemeExtension<SvaColors> {
  const new({
    required this.background,
    required this.surface,
    required this.surfaceSunk,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.granite,
    required this.graniteLight,
    required this.sun,
    required this.onSun,
    required this.sea,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onsight,
    required this.flash,
    required this.redpoint,
    required this.onStyle,
  });

  /// Midnight sun: the dark theme and the brand's home.
  static const midnight = SvaColors(
    background: Color(0xFF1B2240),
    surface: Color(0xFF232B4D),
    surfaceSunk: Color(0xFF141A33),
    line: Color(0xFF343D63),
    text: Color(0xFFF7E7CE),
    textMuted: Color(0xFFA9AECB),
    granite: Color(0xFFE07A5F),
    graniteLight: Color(0xFFF0A08A),
    sun: Color(0xFFF2B544),
    onSun: Color(0xFF1B2240),
    sea: Color(0xFF6FB3C2),
    success: Color(0xFF7CC49A),
    warning: Color(0xFFF2B544),
    danger: Color(0xFFF07A70),
    onsight: Color(0xFF6FB3C2),
    flash: Color(0xFFF2B544),
    redpoint: Color(0xFFE07A5F),
    onStyle: Color(0xFF1B2240),
  );

  /// Daylight: the light theme, the same palette inverted.
  static const daylight = SvaColors(
    background: Color(0xFFFBF5EC),
    surface: Color(0xFFFFFFFF),
    surfaceSunk: Color(0xFFF3EADB),
    line: Color(0xFFE4D8C5),
    text: Color(0xFF1B2240),
    textMuted: Color(0xFF5B6185),
    granite: Color(0xFFAC482F),
    graniteLight: Color(0xFFD4694C),
    sun: Color(0xFFAC482F),
    onSun: Color(0xFFFFFFFF),
    sea: Color(0xFF2E6E7E),
    success: Color(0xFF2D764C),
    warning: Color(0xFF85590A),
    danger: Color(0xFFB33A30),
    onsight: Color(0xFF2E6E7E),
    flash: Color(0xFF85590A),
    redpoint: Color(0xFFAC482F),
    onStyle: Color(0xFFFFFFFF),
  );

  /// Page background.
  final Color background;

  /// Cards and sheets.
  final Color surface;

  /// Inputs, wells and the tab bar.
  final Color surfaceSunk;

  /// Borders, dividers and chart grid lines.
  final Color line;

  /// Primary text.
  final Color text;

  /// Secondary text and labels.
  final Color textMuted;

  /// Brand colour: the higher peak, route lines, selected states.
  final Color granite;

  /// The lower peak and secondary brand fills.
  final Color graniteLight;

  /// The accent: the log button, primary actions, personal bests.
  final Color sun;

  /// Text and icons on [sun].
  final Color onSun;

  /// Links, information, water.
  final Color sea;

  /// Success and OK states.
  final Color success;

  /// Warnings and items due soon.
  final Color warning;

  /// Errors, overdue items and destructive actions.
  final Color danger;

  /// Onsight ascents.
  final Color onsight;

  /// Flash ascents.
  final Color flash;

  /// Redpoint ascents.
  final Color redpoint;

  /// Dims the screen behind sheets and dialogs. The same in both themes.
  static const Color scrim = Color(0x66000000);

  /// Text on onsight, flash and redpoint tags.
  final Color onStyle;

  /// Repeats use muted text colour.
  Color get repeat => textMuted;

  /// Attempts are drawn as an outline in muted text colour.
  Color get attempt => textMuted;

  @override
  SvaColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSunk,
    Color? line,
    Color? text,
    Color? textMuted,
    Color? granite,
    Color? graniteLight,
    Color? sun,
    Color? onSun,
    Color? sea,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onsight,
    Color? flash,
    Color? redpoint,
    Color? onStyle,
  }) {
    return SvaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSunk: surfaceSunk ?? this.surfaceSunk,
      line: line ?? this.line,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      granite: granite ?? this.granite,
      graniteLight: graniteLight ?? this.graniteLight,
      sun: sun ?? this.sun,
      onSun: onSun ?? this.onSun,
      sea: sea ?? this.sea,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onsight: onsight ?? this.onsight,
      flash: flash ?? this.flash,
      redpoint: redpoint ?? this.redpoint,
      onStyle: onStyle ?? this.onStyle,
    );
  }

  @override
  SvaColors lerp(SvaColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SvaColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceSunk: mix(surfaceSunk, other.surfaceSunk),
      line: mix(line, other.line),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      granite: mix(granite, other.granite),
      graniteLight: mix(graniteLight, other.graniteLight),
      sun: mix(sun, other.sun),
      onSun: mix(onSun, other.onSun),
      sea: mix(sea, other.sea),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      onsight: mix(onsight, other.onsight),
      flash: mix(flash, other.flash),
      redpoint: mix(redpoint, other.redpoint),
      onStyle: mix(onStyle, other.onStyle),
    );
  }
}
