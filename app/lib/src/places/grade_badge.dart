import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva_ui/sva_ui.dart';

/// A stored grade as a badge, in the system the user chose in settings.
class GradeBadge extends ConsumerWidget {
  const new(this.label, {required this.system, super.key});

  /// The grade as stored, such as `7-`.
  final String label;

  /// The key of [label]'s system, such as `nor`.
  final String? system;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SvaGradeBadge(ref.watch(gradeDisplayProvider)(label, system));
}
