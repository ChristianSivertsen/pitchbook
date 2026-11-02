import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/form_parts.dart';
import 'package:sva/src/places/route_search_screen.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// A climb being logged, with the route as search showed it.
typedef PendingClimb = ({RouteHit hit, ClimbDraft draft});

/// Styles in the order climbers rank them (DESIGN.md, Data visualisation).
const List<AscentStyle> _styleOrder = [
  AscentStyle.onsight,
  AscentStyle.flash,
  AscentStyle.redpoint,
  AscentStyle.repeat,
  AscentStyle.attempt,
];

const _ropeTypes = ['lead', 'follow', 'toprope', 'solo'];

/// The fields for one outdoor climb: route, style, tries, rope, feel,
/// personal grade, tags and quality. Styles the rules rule out (M1-4) are
/// struck through, with a hint saying why.
class ClimbEditor extends ConsumerStatefulWidget {
  const new({
    required this.earlierInSession,
    required this.onChanged,
    super.key,
  });

  /// Climbs already added to this session, which count for the rules.
  final List<PendingClimb> earlierInSession;

  /// The climb as filled in so far, or `null` until it has a route and a
  /// style.
  final ValueChanged<PendingClimb?> onChanged;

  @override
  ConsumerState<ClimbEditor> createState() => _ClimbEditorState();
}

class _ClimbEditorState extends ConsumerState<ClimbEditor> {
  RouteHit? _hit;
  AscentStyle? _style;
  var _tries = 1;
  var _rope = 'lead';
  String? _feel;
  String? _grade;
  var _tags = <String>{};
  int? _quality;

  bool get _boulder => _hit?.route.discipline == 'boulder';

  RouteHistory _history() {
    final hit = _hit!;
    final logged = ref.watch(routeLogProvider(hit.route.id)).value ?? const [];
    return RouteHistory.from([
      ...logged,
      for (final climb in widget.earlierInSession)
        if (climb.hit.route.id == hit.route.id)
          (style: climb.draft.style, tries: climb.draft.tries),
    ], boulder: _boulder);
  }

  void _emit() {
    final hit = _hit;
    final style = _style;
    widget.onChanged(
      hit == null || style == null
          ? null
          : (
              hit: hit,
              draft: ClimbDraft(
                routeId: hit.route.id,
                style: style,
                tries: _tries,
                ascentType: _boulder ? 'boulder' : _rope,
                feel: _feel,
                personalGradeId: _grade == null
                    ? null
                    : seedId('grade:${_boulder ? 'font' : 'nor'}:$_grade'),
                tags: [..._tags],
                qualityStars: _quality,
              ),
            ),
    );
  }

  void _update(VoidCallback change) {
    setState(change);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hit = _hit;
    if (hit == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.logRoute, style: context.svaText.headline),
          SizedBox(
            // Bounded, since the sheet itself scrolls.
            height: 360,
            child: RouteSearch(
              autofocus: false,
              onPick: (picked) => _update(() {
                _hit = picked;
                _style = null;
                _grade = null;
              }),
            ),
          ),
        ],
      );
    }

    final history = _history();
    final allowed = history.allowedStyles;
    final styles = [
      for (final s in _styleOrder)
        if (s != AscentStyle.onsight || history.onsightPossible) s,
    ];
    final style = _style;
    final hint = history.sent
        ? l10n.logHintSent
        : history.earlierTries > 0
        ? l10n.logHintTried(history.earlierTries)
        : _boulder
        ? l10n.logHintBoulder
        : null;
    final system = ref
        .watch(gradeSystemsProvider)
        .value
        ?.where((s) => s.key == (_boulder ? 'font' : 'nor'))
        .firstOrNull;
    List<(String, String)> options(String key) => [
      for (final value
          in attributeSeed.firstWhere((d) => d.key == key).valueKeys)
        (value, l10n.attributeValue(value.replaceAll('.', '_'))),
    ];
    final muted = context.svaText.caption.copyWith(
      color: context.svaColors.textMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RouteHitTile(hit: hit),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _update(() {
              _hit = null;
              _style = null;
            }),
            child: Text(l10n.logChangeRoute),
          ),
        ),
        formGap,
        ChipGroup(
          label: l10n.logStyle,
          options: [for (final s in styles) (s.name, l10n.ascentStyle(s.name))],
          disabled: {
            for (final s in styles)
              if (!allowed.contains(s)) s.name,
          },
          selected: {?style?.name},
          onChanged: (v) => _update(() {
            _style = v.isEmpty ? null : AscentStyle.values.byName(v.single);
            if (_style case final picked?) _tries = history.minTries(picked);
          }),
        ),
        if (hint != null) ...[
          const SizedBox(height: SvaSpace.xs),
          Text(hint, style: muted),
        ],
        if (style != null && history.maxTries(style) > 1) ...[
          formGap,
          _Tries(
            value: _tries,
            min: history.minTries(style),
            max: history.maxTries(style),
            onChanged: (t) => _update(() => _tries = t),
          ),
        ],
        if (!_boulder) ...[
          formGap,
          ChipGroup(
            label: l10n.logRope,
            options: [for (final t in _ropeTypes) (t, l10n.ascentType(t))],
            selected: {_rope},
            onChanged: (v) => _update(() => _rope = v.firstOrNull ?? 'lead'),
          ),
        ],
        formGap,
        ChipGroup(
          label: l10n.logFeel,
          options: options('feel'),
          selected: {?_feel},
          onChanged: (v) => _update(() => _feel = v.firstOrNull),
        ),
        formGap,
        DropdownButtonFormField<String?>(
          key: ValueKey('grade ${hit.route.id}'),
          initialValue: _grade,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.logPersonalGrade),
          items: [
            DropdownMenuItem(child: Text(l10n.logPersonalGradeNone)),
            for (final grade in system?.grades ?? const <Grade>[])
              DropdownMenuItem(value: grade.label, child: Text(grade.label)),
          ],
          onChanged: (g) => _update(() => _grade = g),
        ),
        formGap,
        ChipGroup(
          label: l10n.logTags,
          options: options('tag'),
          multi: true,
          selected: _tags,
          onChanged: (v) => _update(() => _tags = v),
        ),
        formGap,
        ChipGroup(
          label: l10n.logQuality,
          options: [
            for (final n in [1, 2, 3]) ('$n', l10n.logQualityLevel('q$n')),
          ],
          selected: {if (_quality != null) '$_quality'},
          onChanged: (v) =>
              _update(() => _quality = int.tryParse(v.firstOrNull ?? '')),
        ),
      ],
    );
  }
}

/// A tries stepper within the rules' limits.
class _Tries extends StatelessWidget {
  const new({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Text(l10n.logTries, style: context.svaText.label)),
        IconButton(
          tooltip: l10n.logTriesFewer,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(LucideIcons.minus),
        ),
        Semantics(
          liveRegion: true,
          child: Text('$value', style: context.svaText.number),
        ),
        IconButton(
          tooltip: l10n.logTriesMore,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }
}
