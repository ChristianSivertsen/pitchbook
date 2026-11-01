import 'package:flutter/material.dart';

/// Sva text styles from docs/DESIGN.md. Fraunces is for titles only;
/// everything you read or tap is Inter.
///
/// Both fonts are variable fonts bundled in this package, so weights are set
/// with a font variation as well as [FontWeight].
@immutable
class SvaTypography extends ThemeExtension<SvaTypography> {
  const new({
    required this.display,
    required this.title,
    required this.headline,
    required this.body,
    required this.label,
    required this.caption,
    required this.number,
    required this.grade,
  });

  /// Builds the text styles in [color].
  factory withColor(Color color) {
    return SvaTypography(
      display: _fraunces(32, 36, color),
      title: _fraunces(22, 28, color),
      headline: _inter(17, 24, FontWeight.w600, color),
      body: _inter(15, 22, FontWeight.w400, color),
      label: _inter(13, 18, FontWeight.w500, color),
      caption: _inter(12, 16, FontWeight.w400, color),
      number: _inter(22, 26, FontWeight.w600, color, tabular: true),
      grade: _inter(14, 16, FontWeight.w700, color, tabular: true),
    );
  }

  /// Fraunces family name, as declared in this package's pubspec.
  static const String serifFamily = 'Fraunces';

  /// Inter family name, as declared in this package's pubspec.
  static const String sansFamily = 'Inter';

  /// Package that bundles the fonts.
  static const String fontPackage = 'sva_ui';

  /// Screen titles: Feed, History, CV.
  final TextStyle display;

  /// Session titles and section headers.
  final TextStyle title;

  /// Card titles and route names.
  final TextStyle headline;

  /// Running text.
  final TextStyle body;

  /// Buttons, chips and form labels.
  final TextStyle label;

  /// Metadata and timestamps.
  final TextStyle caption;

  /// Stats; tabular figures so columns line up.
  final TextStyle number;

  /// Grade chips; tabular figures.
  final TextStyle grade;

  static TextStyle _fraunces(double size, double lineHeight, Color color) {
    return TextStyle(
      fontFamily: serifFamily,
      package: fontPackage,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
      color: color,
    );
  }

  static TextStyle _inter(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, {
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: sansFamily,
      package: fontPackage,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      color: color,
    );
  }

  @override
  SvaTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? headline,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? number,
    TextStyle? grade,
  }) {
    return SvaTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      number: number ?? this.number,
      grade: grade ?? this.grade,
    );
  }

  @override
  SvaTypography lerp(SvaTypography? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return SvaTypography(
      display: mix(display, other.display),
      title: mix(title, other.title),
      headline: mix(headline, other.headline),
      body: mix(body, other.body),
      label: mix(label, other.label),
      caption: mix(caption, other.caption),
      number: mix(number, other.number),
      grade: mix(grade, other.grade),
    );
  }
}
