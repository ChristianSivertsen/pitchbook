import 'package:flutter/widgets.dart';

/// Spacing scale from docs/DESIGN.md, in logical pixels.
abstract final class SvaSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Side padding of a screen.
  static const double screen = md;

  /// Smallest size of anything you can tap.
  static const double minTouchTarget = 44;
}

/// Corner radii from docs/DESIGN.md.
abstract final class SvaRadius {
  /// Grade badges.
  static const Radius badge = Radius.circular(6);

  /// Chips and inputs.
  static const Radius small = Radius.circular(8);

  /// Cards.
  static const Radius card = Radius.circular(12);

  /// Large cards and photos.
  static const Radius large = Radius.circular(16);

  /// The top corners of sheets.
  static const Radius sheet = Radius.circular(24);

  /// The log button.
  static const Radius logButton = Radius.circular(16);
}

/// Motion durations from docs/DESIGN.md. Use [resolve] so motion turns off
/// when the system asks to reduce motion.
abstract final class SvaMotion {
  /// Taps and chip toggles.
  static const Duration tap = Duration(milliseconds: 120);

  /// Cards and list changes.
  static const Duration change = Duration(milliseconds: 200);

  /// Sheets sliding in and out.
  static const Duration sheet = Duration(milliseconds: 300);

  /// A new personal best: the only celebratory motion.
  static const Duration celebrate = Duration(milliseconds: 600);

  /// Standard easing for things appearing.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Standard easing for things leaving.
  static const Curve easeIn = Curves.easeInCubic;

  /// Returns [duration], or [Duration.zero] when the user has asked the
  /// system to reduce motion.
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
