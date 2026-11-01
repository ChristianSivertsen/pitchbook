import 'package:flutter/material.dart';

import 'package:sva_ui/src/brand/sva_mark.dart';
import 'package:sva_ui/src/theme/sva_colors.dart';
import 'package:sva_ui/src/theme/sva_theme.dart';
import 'package:sva_ui/src/theme/sva_tokens.dart';

/// Shows every Sva token in the current theme, for design review.
/// Only reachable in debug builds.
class SvaTokenPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    final text = context.svaText;
    return ListView(
      padding: const EdgeInsets.all(SvaSpace.screen),
      children: [
        const Center(child: SvaLockup()),
        const SizedBox(height: SvaSpace.xl),
        Text('Colours', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        Wrap(
          spacing: SvaSpace.xs,
          runSpacing: SvaSpace.xs,
          children: [
            for (final (name, color) in _swatches(colors))
              _Swatch(name: name, color: color),
          ],
        ),
        const SizedBox(height: SvaSpace.xl),
        Text('Type', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        Text('Display', style: text.display),
        Text('Title', style: text.title),
        Text('Headline', style: text.headline),
        Text('Body text for running copy.', style: text.body),
        Text('Label', style: text.label),
        Text('Caption', style: text.caption),
        Text('1 234 m', style: text.number),
        const SizedBox(height: SvaSpace.xxs),
        Align(
          alignment: Alignment.centerLeft,
          child: _Tag(label: '7a+', color: colors.text, textStyle: text.grade),
        ),
        const SizedBox(height: SvaSpace.xl),
        Text('Spacing', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        for (final (name, value) in _spacing)
          Padding(
            padding: const EdgeInsets.only(bottom: SvaSpace.xxs),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(name, style: text.caption)),
                Container(
                  width: value,
                  height: SvaSpace.sm,
                  color: colors.granite,
                ),
              ],
            ),
          ),
        const SizedBox(height: SvaSpace.xl),
        Text('Radius', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        Wrap(
          spacing: SvaSpace.xs,
          runSpacing: SvaSpace.xs,
          children: [
            for (final (name, radius) in _radii)
              _RadiusSample(name: name, radius: radius),
          ],
        ),
        const SizedBox(height: SvaSpace.xl),
        Text('Motion', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        for (final (name, duration) in _motion)
          Text('$name: ${duration.inMilliseconds} ms', style: text.body),
        const SizedBox(height: SvaSpace.xl),
        Text('Components', style: text.title),
        const SizedBox(height: SvaSpace.xs),
        Wrap(
          spacing: SvaSpace.xs,
          runSpacing: SvaSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Save session')),
            OutlinedButton(onPressed: () {}, child: const Text('Add climb')),
            _Tag(label: 'Onsight', color: colors.onsight),
            _Tag(label: 'Flash', color: colors.flash),
            _Tag(label: 'Redpoint', color: colors.redpoint),
          ],
        ),
      ],
    );
  }

  static List<(String, Color)> _swatches(SvaColors c) => [
    ('background', c.background),
    ('surface', c.surface),
    ('surfaceSunk', c.surfaceSunk),
    ('line', c.line),
    ('text', c.text),
    ('textMuted', c.textMuted),
    ('granite', c.granite),
    ('graniteLight', c.graniteLight),
    ('sun', c.sun),
    ('sea', c.sea),
    ('success', c.success),
    ('warning', c.warning),
    ('danger', c.danger),
    ('onSun', c.onSun),
    ('onStyle', c.onStyle),
  ];

  static const List<(String, double)> _spacing = [
    ('xxs 4', SvaSpace.xxs),
    ('xs 8', SvaSpace.xs),
    ('sm 12', SvaSpace.sm),
    ('md 16', SvaSpace.md),
    ('lg 20', SvaSpace.lg),
    ('xl 24', SvaSpace.xl),
    ('xxl 32', SvaSpace.xxl),
    ('xxxl 40', SvaSpace.xxxl),
    ('huge 48', SvaSpace.huge),
  ];

  static const List<(String, Radius)> _radii = [
    ('badge', SvaRadius.badge),
    ('small', SvaRadius.small),
    ('card', SvaRadius.card),
    ('large', SvaRadius.large),
    ('sheet', SvaRadius.sheet),
  ];

  static const List<(String, Duration)> _motion = [
    ('tap', SvaMotion.tap),
    ('change', SvaMotion.change),
    ('sheet', SvaMotion.sheet),
    ('celebrate', SvaMotion.celebrate),
  ];
}

class _Swatch extends StatelessWidget {
  const new({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(SvaRadius.small),
              border: Border.all(color: colors.line),
            ),
          ),
          const SizedBox(height: SvaSpace.xxs),
          Text(name, style: context.svaText.caption),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const new({required this.label, required this.color, this.textStyle});

  final String label;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(SvaRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SvaSpace.xs,
          vertical: SvaSpace.xxs,
        ),
        child: Text(
          label,
          style: (textStyle ?? context.svaText.label).copyWith(
            color: color == context.svaColors.text
                ? context.svaColors.background
                : context.svaColors.onStyle,
          ),
        ),
      ),
    );
  }
}

class _RadiusSample extends StatelessWidget {
  const new({required this.name, required this.radius});

  final String name;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.all(radius),
          ),
        ),
        const SizedBox(height: SvaSpace.xxs),
        Text(name, style: context.svaText.caption),
      ],
    );
  }
}
