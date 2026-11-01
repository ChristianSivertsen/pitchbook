import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  group('SvaTheme', () {
    test('M0-4: Midnight sun is dark and Daylight is light', () {
      expect(SvaTheme.midnight().brightness, Brightness.dark);
      expect(SvaTheme.daylight().brightness, Brightness.light);
    });

    test('M0-4: both themes carry the Sva colour and type tokens', () {
      for (final theme in [SvaTheme.midnight(), SvaTheme.daylight()]) {
        expect(theme.extension<SvaColors>(), isNotNull);
        expect(theme.extension<SvaTypography>(), isNotNull);
      }
      expect(SvaTheme.midnight().extension<SvaColors>(), SvaColors.midnight);
    });

    test('M0-4: titles use Fraunces and everything else Inter', () {
      final type = SvaTypography.withColor(const Color(0xFF000000));
      for (final style in [type.display, type.title]) {
        expect(style.fontFamily, contains(SvaTypography.serifFamily));
      }
      for (final style in [
        type.headline,
        type.body,
        type.label,
        type.caption,
        type.number,
        type.grade,
      ]) {
        expect(style.fontFamily, contains(SvaTypography.sansFamily));
      }
    });

    test('M0-4: numbers and grades use tabular figures', () {
      final type = SvaTypography.withColor(const Color(0xFF000000));
      for (final style in [type.number, type.grade]) {
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('M0-4: colour tokens interpolate for theme animations', () {
      final mid = SvaColors.midnight.lerp(SvaColors.daylight, 0.5);
      expect(mid.text, isNot(SvaColors.midnight.text));
      expect(
        SvaColors.midnight.lerp(SvaColors.daylight, 1).text,
        SvaColors.daylight.text,
      );
    });
  });

  group('SvaMotion', () {
    testWidgets('M0-4: motion turns off when the system reduces motion', (
      tester,
    ) async {
      late Duration normal;
      late Duration reduced;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            normal = SvaMotion.resolve(context, SvaMotion.sheet);
            return MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = SvaMotion.resolve(context, SvaMotion.sheet);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );
      expect(normal, SvaMotion.sheet);
      expect(reduced, Duration.zero);
    });
  });

  group('SvaMark', () {
    testWidgets('M0-4: the mark is announced as Sva', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SvaTheme.midnight(),
          home: const Center(child: SvaMark()),
        ),
      );
      expect(find.bySemanticsLabel('Sva'), findsOneWidget);
    });
  });
}
