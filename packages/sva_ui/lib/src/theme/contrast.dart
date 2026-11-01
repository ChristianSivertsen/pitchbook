import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.x contrast ratio between two opaque colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Minimum contrast for body text and labels (WCAG AA).
const double minTextContrast = 4.5;

/// Minimum contrast for large text, icons and chart marks (WCAG AA).
const double minLargeContrast = 3;

double _relativeLuminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
