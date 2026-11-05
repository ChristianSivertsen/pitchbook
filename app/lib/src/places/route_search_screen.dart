import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/grade_badge.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// Search for outdoor routes by route or crag name. With an empty field it
/// lists your recent and nearby routes.
class RouteSearchScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeSearchTitle)),
      body: RouteSearch(
        onPick: (hit) => context.push(Routes.route(hit.route.id)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SvaSpace.screen),
          child: OutlinedButton.icon(
            onPressed: () => context.push(Routes.routeNew),
            icon: const Icon(LucideIcons.plus),
            label: Text(l10n.routeAdd),
          ),
        ),
      ),
    );
  }
}

/// A search field with live results. The log sheet reuses it to pick the
/// route for a climb (M2-3).
class RouteSearch extends ConsumerStatefulWidget {
  const new({required this.onPick, this.autofocus = true, super.key});

  final ValueChanged<RouteHit> onPick;

  /// Whether the field takes focus (and opens the keyboard) at once.
  final bool autofocus;

  @override
  ConsumerState<RouteSearch> createState() => _RouteSearchState();
}

class _RouteSearchState extends ConsumerState<RouteSearch> {
  final _field = TextEditingController();
  var _term = '';

  /// What the list showed for the last finished search, kept on screen
  /// while the next one runs so results do not flicker as you type.
  List<RouteHit>? _shown;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final current = ref.watch(routeSearchProvider(_term)).value;
    if (current != null) _shown = current;
    final hits = _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(SvaSpace.screen),
          child: TextField(
            controller: _field,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.routeSearchField,
              prefixIcon: Icon(LucideIcons.search, color: colors.textMuted),
            ),
            onChanged: (value) => setState(() => _term = value.trim()),
          ),
        ),
        Expanded(
          child: switch (hits) {
            null => const SizedBox.shrink(),
            // "No match" only once this term's search has finished.
            [] when current == null => const SizedBox.shrink(),
            [] => Padding(
              padding: const EdgeInsets.all(SvaSpace.xxl),
              child: Text(
                _term.isEmpty
                    ? l10n.routeSearchEmpty
                    : l10n.routeSearchNoMatch(_term),
                style: context.svaText.body.copyWith(color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            final hits => ListView.separated(
              itemCount: hits.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.line),
              itemBuilder: (context, i) => RouteHitTile(
                hit: hits[i],
                onTap: () => widget.onPick(hits[i]),
              ),
            ),
          },
        ),
      ],
    );
  }
}

/// One route in a list: name and grade, then crag, discipline and pitches.
class RouteHitTile extends StatelessWidget {
  const new({required this.hit, this.onTap, super.key});

  final RouteHit hit;

  /// `null` for a tile that only shows the route.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.svaText;
    final route = hit.route;
    final facts = [
      ?hit.crag,
      l10n.discipline(route.discipline),
      if (route.pitchCount > 1) l10n.routePitches(route.pitchCount),
    ].where((f) => f.isNotEmpty).join(' · ');
    return ListTile(
      onTap: onTap,
      minTileHeight: SvaSpace.minTouchTarget,
      contentPadding: const EdgeInsets.symmetric(horizontal: SvaSpace.screen),
      title: Text(route.name ?? '', style: text.headline),
      subtitle: Text(
        facts,
        style: text.caption.copyWith(color: context.svaColors.textMuted),
      ),
      trailing: switch (hit.grade) {
        final grade? => GradeBadge(grade, system: hit.gradeSystem),
        null => null,
      },
    );
  }
}
