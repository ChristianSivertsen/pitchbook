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
