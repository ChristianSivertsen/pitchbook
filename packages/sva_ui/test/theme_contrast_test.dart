import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/sva_ui.dart';

/// Every foreground/background pair the design language uses for text,
/// from docs/DESIGN.md. Large text, icons and chart marks only need 3 : 1,
/// but these are all held to the 4.5 : 1 text standard.
List<(String, Color, Color)> textPairs(SvaColors c) => [
  ('text on background', c.text, c.background),
  ('text on surface', c.text, c.surface),
  ('text on sunk surface', c.text, c.surfaceSunk),
  ('muted text on background', c.textMuted, c.background),
  ('muted text on surface', c.textMuted, c.surface),
  ('muted text on sunk surface', c.textMuted, c.surfaceSunk),
  ('label on accent', c.onSun, c.sun),
  ('granite on background', c.granite, c.background),
  ('sea links on background', c.sea, c.background),
  ('success on background', c.success, c.background),
  ('warning on background', c.warning, c.background),
  ('danger on background', c.danger, c.background),
  ('onsight on background', c.onsight, c.background),
  ('flash on background', c.flash, c.background),
  ('redpoint on background', c.redpoint, c.background),
  ('label on onsight tag', c.onStyle, c.onsight),
  ('label on flash tag', c.onStyle, c.flash),
  ('label on redpoint tag', c.onStyle, c.redpoint),
  ('chip label on selected chip', c.background, c.text),
];

/// Marks that only need the large-text and icon standard.
List<(String, Color, Color)> markPairs(SvaColors c) => [
  ('lower peak on background', c.graniteLight, c.background),
  ('attempt outline on background', c.attempt, c.background),
];

void main() {
  for (final (name, colors) in [
    ('Midnight sun', SvaColors.midnight),
    ('Daylight', SvaColors.daylight),
  ]) {
    group(name, () {
      test('M0-4: every text pair meets WCAG AA (4.5 : 1)', () {
        for (final (pair, fg, bg) in textPairs(colors)) {
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(minTextContrast),
            reason: '$name: $pair',
          );
        }
      });

      test('M0-4: every icon and mark pair meets WCAG AA (3 : 1)', () {
        for (final (pair, fg, bg) in markPairs(colors)) {
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(minLargeContrast),
            reason: '$name: $pair',
          );
        }
      });
    });
  }
}
