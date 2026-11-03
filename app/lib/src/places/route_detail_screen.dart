import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/labels.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// One route: grade, discipline, length, pitches, details and your climbs
/// on it.
class RouteDetailScreen extends ConsumerWidget {
  const new({required this.routeId, super.key});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hit = ref.watch(routeHitProvider(routeId));
    return Scaffold(
      appBar: AppBar(),
      body: switch (hit) {
        AsyncData(value: final hit?) => _RouteDetail(hit: hit),
        AsyncData() || AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(SvaSpace.xxl),
            child: Text(
              l10n.routeNotFound,
              style: context.svaText.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncLoading() => const SizedBox.shrink(),
      },
    );
  }
}

class _RouteDetail extends ConsumerWidget {
  const new({required this.hit});

  final RouteHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final text = context.svaText;
    final route = hit.route;
    final details = ref.watch(routeDetailsProvider(route.id)).value;
    final climbs = ref.watch(routeClimbsProvider(route.id)).value;
    final facts = [
      l10n.discipline(route.discipline),
      if (route.lengthM case final length?) l10n.routeLength(length.round()),
      if (route.pitchCount > 1) l10n.routePitches(route.pitchCount),
    ].where((f) => f.isNotEmpty).join(' · ');
    final tags = details == null ? const <String>[] : detailTags(l10n, details);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: SvaSpace.xl, bottom: SvaSpace.xs),
      child: Semantics(header: true, child: Text(title, style: text.headline)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SvaSpace.screen,
        0,
        SvaSpace.screen,
        SvaSpace.xxl,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(route.name ?? '', style: text.title),
        ),
        const SizedBox(height: SvaSpace.xs),
        Wrap(
          spacing: SvaSpace.xs,
          runSpacing: SvaSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SvaGradeBadge(hit.grade ?? l10n.routeUngraded),
            if (hit.crag case final crag?)
              Text(crag, style: text.body.copyWith(color: colors.textMuted)),
          ],
        ),
        if (_yourTake(l10n, climbs) case final take?) ...[
          const SizedBox(height: SvaSpace.xs),
          Text(take, style: text.label),
        ],
        const SizedBox(height: SvaSpace.xs),
        Text(facts, style: text.body),
        if (tags.isNotEmpty) ...[
          section(l10n.routeDetails),
          Wrap(
            spacing: SvaSpace.xs,
            runSpacing: SvaSpace.xs,
            children: [for (final tag in tags) SvaTag(tag)],
          ),
        ],
        section(l10n.routeYourClimbs),
        if (climbs case final climbs? when climbs.isEmpty)
          Text(
            l10n.routeNotClimbed,
            style: text.body.copyWith(color: colors.textMuted),
          )
        else
          for (final climb in climbs ?? const <RouteClimb>[])
            _ClimbRow(climb: climb, currentGrade: hit.grade),
      ],
    );
  }

  /// Your own grade for the route, from the newest climb that has one, or
  /// else how the newest climb with a feel felt. Shown under the official
  /// grade.
  static String? _yourTake(AppLocalizations l10n, List<RouteClimb>? climbs) {
    for (final climb in climbs ?? const <RouteClimb>[]) {
      if (climb.personalGrade case final grade?) {
        return l10n.routeYourGrade(grade);
      }
    }
    for (final climb in climbs ?? const <RouteClimb>[]) {
      if (climb.ascent.feel case final feel?) {
        final label = l10n.attributeValue(feel.replaceAll('.', '_'));
        // An unknown key has no words yet: say nothing rather than half.
        if (label.isNotEmpty) return l10n.routeYourFeel(label);
      }
    }
    return null;
  }
}

class _ClimbRow extends StatelessWidget {
  const new({required this.climb, required this.currentGrade});

  final RouteClimb climb;

  /// The route's grade now, to point out climbs logged before a regrade.
  final String? currentGrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.svaText;
    final ascent = climb.ascent;
    final date = climb.date;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SvaSpace.xs),
      // Wraps instead of squeezing the date when text is large.
      child: Wrap(
        spacing: SvaSpace.xs,
        runSpacing: SvaSpace.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(formatDay(l10n, date), style: text.body),
          SvaStyleTag(
            style: ascent.style,
            label: l10n.ascentStyle(ascent.style),
          ),
          Text(
            l10n.ascentTries(ascent.tries),
            style: text.caption.copyWith(color: context.svaColors.textMuted),
          ),
          if (climb.officialGrade case final then?
              when currentGrade != null && then != currentGrade)
            Text(
              l10n.routeLoggedAt(then),
              style: text.caption.copyWith(color: context.svaColors.textMuted),
            ),
          if (climb.personalGrade case final grade?)
            Text(
              l10n.routeYourGrade(grade),
              style: text.caption.copyWith(color: context.svaColors.textMuted),
            ),
        ],
      ),
    );
  }
}
