import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/sva_ui.dart';

/// Foreground colours that docs/DESIGN.md uses as text.
List<(String, Color)> textColours(SvaColors c) => [
  ('text', c.text),
  ('muted text', c.textMuted),
  ('granite', c.granite),
  ('sea links', c.sea),
  ('success', c.success),
  ('warning', c.warning),
  ('danger', c.danger),
  ('onsight', c.onsight),
  ('flash', c.flash),
  ('redpoint', c.redpoint),
];

/// Text on a filled background (labels on buttons, tags and selected chips).
List<(String, Color, Color)> filledTextPairs(SvaColors c) => [
  ('label on accent button', c.onSun, c.sun),
  ('label on onsight tag', c.onStyle, c.onsight),
  ('label on flash tag', c.onStyle, c.flash),
  ('label on redpoint tag', c.onStyle, c.redpoint),
  ('label on selected chip', c.background, c.text),
];

/// Chart series, the accent fill and outlines: these need 3 : 1 (WCAG AA
/// for graphics and large text).
List<(String, Color)> markColours(SvaColors c) => [
  ('chart series granite', c.granite),
  ('chart series sun', c.sun),
  ('chart series sea', c.sea),
  ('chart series and secondary fill graniteLight', c.graniteLight),
  ('chart series and attempt outline textMuted', c.textMuted),
  ('log button fill', c.sun),
];

void main() {
  for (final (name, colors) in [
    ('Midnight sun', SvaColors.midnight),
    ('Daylight', SvaColors.daylight),
  ]) {
    // Text is read on the page, on cards and in wells.
    final textBackgrounds = [
      ('background', colors.background),
      ('surface', colors.surface),
      ('sunk surface', colors.surfaceSunk),
    ];
    // Charts and fills sit on the page and on cards, never in wells.
    final markBackgrounds = [
      ('background', colors.background),
      ('surface', colors.surface),
    ];

    group(name, () {
      test('M0-4: every text colour meets WCAG AA (4.5 : 1) where used', () {
        for (final (fg, fgColour) in textColours(colors)) {
          for (final (bg, bgColour) in textBackgrounds) {
            expect(
              contrastRatio(fgColour, bgColour),
              greaterThanOrEqualTo(minTextContrast),
              reason: '$name: $fg on $bg',
            );
          }
        }
        for (final (pair, fg, bg) in filledTextPairs(colors)) {
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(minTextContrast),
            reason: '$name: $pair',
          );
        }
      });

      test('M0-4: every chart mark and fill meets WCAG AA (3 : 1)', () {
        for (final (mark, markColour) in markColours(colors)) {
          for (final (bg, bgColour) in markBackgrounds) {
            expect(
              contrastRatio(markColour, bgColour),
              greaterThanOrEqualTo(minLargeContrast),
              reason: '$name: $mark on $bg',
            );
          }
        }
      });
    });
  }
}
