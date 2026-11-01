import 'package:flutter/material.dart';

import 'package:sva_ui/src/theme/sva_colors.dart';
import 'package:sva_ui/src/theme/sva_theme.dart';
import 'package:sva_ui/src/theme/sva_tokens.dart';

/// The Sva mark: a sun, a peak and a higher peak by the sea, which also
/// reads as a rising graph. In Midnight sun the sun sits low on the left;
/// in Daylight it stands high on the right. When the theme changes, the sun
/// travels between the two. Drawn in code so it is sharp at every size.
/// The source files live in `assets/brand/`.
class SvaMark extends StatelessWidget {
  const new({this.size = 32, super.key});

  /// Width and height of the mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDay = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: 'Sva',
      image: true,
      // With no begin value the first frame starts at the end, so the mark
      // only animates when the theme changes, not when it first appears.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: isDay ? 1 : 0),
        duration: SvaMotion.resolve(context, SvaMotion.daybreak),
        curve: Curves.easeInOutCubic,
        builder: (context, daylight, _) => CustomPaint(
          size: Size.square(size),
          painter: SvaMarkPainter(daylight: daylight),
        ),
      ),
    );
  }
}

/// The mark above the lowercase wordmark, for splash and onboarding.
class SvaLockup extends StatelessWidget {
  const new({this.markSize = 64, super.key});

  /// Size of the mark; the wordmark scales with it.
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final style = context.svaText.display.copyWith(fontSize: markSize * 0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvaMark(size: markSize),
        ExcludeSemantics(child: Text('sva', style: style)),
      ],
    );
  }
}

/// Paints the mark at a point between night (`daylight` 0) and day (1).
/// Public only so tests can read where the sun is.
@visibleForTesting
class SvaMarkPainter extends CustomPainter {
  const new({required this.daylight});

  /// 0 is Midnight sun, 1 is Daylight; values between are mid-animation.
  final double daylight;

  // Coordinates use the 64 x 64 space of assets/brand/*.svg.
  static const Offset _nightSun = Offset(9, 47);
  static const Offset _daySun = Offset(57, 10);

  /// Pulls the path up into an arc, so the sun clears the lower peak and
  /// slips behind the summit on its way across.
  static const Offset _arcControl = Offset(12, 0);

  /// Where the sun's centre is, in the 64 x 64 space.
  Offset get sunCentre {
    final t = daylight;
    final u = 1 - t;
    return _nightSun * (u * u) + _arcControl * (2 * u * t) + _daySun * (t * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const night = SvaColors.midnight;
    const day = SvaColors.daylight;
    Paint fill(Color atNight, Color atDay) =>
        Paint()..color = Color.lerp(atNight, atDay, daylight)!;

    // The sun goes first, so it passes behind the peaks as it rises.
    canvas
      ..scale(size.width / 64, size.height / 64)
      ..drawCircle(sunCentre, 6, fill(night.sun, day.graniteLight));
    final higher = Path()
      ..moveTo(26, 52)
      ..lineTo(41, 12)
      ..cubicTo(43, 7, 47, 7, 49, 12)
      ..lineTo(62, 52)
      ..close();
    canvas.drawPath(higher, fill(night.granite, day.text));
    final lower = Path()
      ..moveTo(14, 52)
      ..lineTo(25, 31)
      ..cubicTo(27, 27, 30, 27, 32, 31)
      ..lineTo(42, 52)
      ..close();
    canvas.drawPath(lower, fill(night.graniteLight, day.textMuted));
  }

  @override
  bool shouldRepaint(SvaMarkPainter oldDelegate) =>
      daylight != oldDelegate.daylight;
}
