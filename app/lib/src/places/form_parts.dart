import 'package:flutter/material.dart';
import 'package:sva_ui/sva_ui.dart';

/// A labelled group of tappable chips. With [multi] any number can be
/// picked; otherwise one or none (tapping the picked chip clears it).
class ChipGroup extends StatelessWidget {
  const new({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multi = false,
    super.key,
  });

  final String label;

  /// Value keys and their display text, in display order.
  final List<(String, String)> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The group's semantic label already says this.
          ExcludeSemantics(
            child: Text(
              label,
              style: context.svaText.label.copyWith(
                color: context.svaColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: SvaSpace.xs),
          Wrap(
            spacing: SvaSpace.xs,
            runSpacing: SvaSpace.xs,
            children: [
              for (final (value, text) in options)
                FilterChip(
                  label: Text(text),
                  selected: selected.contains(value),
                  onSelected: (on) => onChanged(switch ((multi, on)) {
                    (true, true) => {...selected, value},
                    (true, false) => {...selected}..remove(value),
                    (false, true) => {value},
                    (false, false) => const {},
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A number typed with either a decimal comma or point, or `null`.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Space between form fields.
const formGap = SizedBox(height: SvaSpace.lg);
