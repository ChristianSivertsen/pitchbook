import 'package:flutter/material.dart';
import 'package:sva_ui/src/theme/sva_theme.dart';
import 'package:sva_ui/src/theme/sva_tokens.dart';

/// A grade as a badge: `text` fill, `background` label, tabular figures
/// (docs/DESIGN.md, Components).
class SvaGradeBadge extends StatelessWidget {
  const new(this.label, {super.key});

  /// The grade as the user reads it, such as `7-`.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.text,
        borderRadius: const BorderRadius.all(SvaRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SvaSpace.xs,
          vertical: SvaSpace.xxs,
        ),
        child: Text(
          label,
          style: context.svaText.grade.copyWith(color: colors.background),
        ),
      ),
    );
  }
}

/// A read-only chip for a known fact, such as a route's rock or holds:
/// `surfaceSunk` fill and a `text` label (docs/DESIGN.md, Chip).
class SvaTag extends StatelessWidget {
  const new(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunk,
        borderRadius: const BorderRadius.all(SvaRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SvaSpace.sm,
          vertical: SvaSpace.xs,
        ),
        child: Text(
          label,
          style: context.svaText.label.copyWith(color: colors.text),
        ),
      ),
    );
  }
}

/// A climb's style in its climbing colour; repeats and attempts are quiet
/// outlines (docs/DESIGN.md, Style tag).
class SvaStyleTag extends StatelessWidget {
  const new({required this.style, required this.label, super.key});

  /// The style's stable key, such as `flash`.
  final String style;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    final fill = switch (style) {
      'onsight' => colors.onsight,
      'flash' => colors.flash,
      'redpoint' => colors.redpoint,
      _ => null,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: fill == null ? Border.all(color: colors.textMuted) : null,
        borderRadius: const BorderRadius.all(SvaRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SvaSpace.xs,
          vertical: SvaSpace.xxs,
        ),
        child: Text(
          label,
          style: context.svaText.caption.copyWith(
            color: fill == null ? colors.textMuted : colors.onStyle,
          ),
        ),
      ),
    );
  }
}
