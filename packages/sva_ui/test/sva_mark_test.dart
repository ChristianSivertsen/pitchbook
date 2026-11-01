import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/src/brand/sva_mark.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  Widget mark({required bool day, bool reduceMotion = false}) => MaterialApp(
    theme: SvaTheme.daylight(),
    darkTheme: SvaTheme.midnight(),
    themeMode: day ? ThemeMode.light : ThemeMode.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: const Center(child: SvaMark(size: 64)),
  );

  SvaMarkPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(SvaMark),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as SvaMarkPainter;

  testWidgets(
    'M0-9: the sun is upper right in Daylight, low left in Midnight sun',
    (tester) async {
      await tester.pumpWidget(mark(day: true));
      final day = painter(tester).sunCentre;
      // Right of the higher peak's summit (x 45) and in the top third.
      expect(day.dx, greaterThan(45));
      expect(day.dy, lessThan(64 / 3));

      await tester.pumpWidget(mark(day: false));
      await tester.pumpAndSettle();
      final night = painter(tester).sunCentre;
      // Left of the lower peak (x 14) and near the horizon (y 52).
      expect(night.dx, lessThan(14));
      expect(night.dy, greaterThan(40));
    },
  );

  testWidgets('M0-9: switching theme moves the sun smoothly', (tester) async {
    await tester.pumpWidget(mark(day: false));
    await tester.pumpAndSettle();
    expect(painter(tester).daylight, 0, reason: 'no animation on first show');

    await tester.pumpWidget(mark(day: true));
    // The app's own theme crossfade flips brightness halfway through.
    await tester.pump(kThemeAnimationDuration);
    final positions = <double>[];
    for (var i = 0; i < 8; i++) {
      await tester.pump(SvaMotion.daybreak ~/ 10);
      positions.add(painter(tester).daylight);
    }
    expect(positions.first, greaterThan(0));
    expect(positions.last, lessThan(1));
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]));
    }
    await tester.pumpAndSettle();
    expect(painter(tester).daylight, 1);

    // The path arcs upwards: halfway, the sun is above the lower peak's
    // summit (y 28) instead of passing through it.
    expect(const SvaMarkPainter(daylight: 0.5).sunCentre.dy, lessThan(28));
  });

  testWidgets('M0-9: with reduce motion the sun moves straight there', (
    tester,
  ) async {
    await tester.pumpWidget(mark(day: false, reduceMotion: true));
    await tester.pumpWidget(mark(day: true, reduceMotion: true));
    await tester.pump(kThemeAnimationDuration);
    await tester.pump();
    expect(painter(tester).daylight, 1);
  });
}
