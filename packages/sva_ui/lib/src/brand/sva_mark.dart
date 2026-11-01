import 'package:flutter/material.dart';

import 'package:sva_ui/src/theme/sva_theme.dart';

/// The Sva mark: a low sun, a peak and a higher peak by the sea, which also
/// reads as a rising graph. Drawn in code so it is sharp at every size and
/// follows the current theme. The source files live in `assets/brand/`.
class SvaMark extends StatelessWidget {
  const new({this.size = 32, super.key});

  /// Width and height of the mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Sva',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(
          sun: isDark ? colors.sun : colors.graniteLight,
          higherPeak: isDark ? colors.granite : colors.text,
          lowerPeak: isDark ? colors.graniteLight : colors.textMuted,
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

class _MarkPainter extends CustomPainter {
  const new({
    required this.sun,
    required this.higherPeak,
    required this.lowerPeak,
  });

  final Color sun;
  final Color higherPeak;
  final Color lowerPeak;

  @override
  void paint(Canvas canvas, Size size) {
    // Paths use the 64 x 64 coordinate space of assets/brand/*.svg.
    canvas
      ..scale(size.width / 64, size.height / 64)
      ..drawCircle(const Offset(9, 47), 6, Paint()..color = sun);
    final higher = Path()
      ..moveTo(26, 52)
      ..lineTo(41, 12)
      ..cubicTo(43, 7, 47, 7, 49, 12)
      ..lineTo(62, 52)
      ..close();
    canvas.drawPath(higher, Paint()..color = higherPeak);
    final lower = Path()
      ..moveTo(14, 52)
      ..lineTo(25, 31)
      ..cubicTo(27, 27, 30, 27, 32, 31)
      ..lineTo(42, 52)
      ..close();
    canvas.drawPath(lower, Paint()..color = lowerPeak);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      sun != oldDelegate.sun ||
      higherPeak != oldDelegate.higherPeak ||
      lowerPeak != oldDelegate.lowerPeak;
}
