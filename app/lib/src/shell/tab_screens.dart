import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/labels.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// Feed tab: your sessions, newest first. The full session cards arrive
/// in M2-7; until then each session is a simple row.
class FeedScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(mySessionsProvider).value ?? const [];
    if (sessions.isNotEmpty) {
      return SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SvaSpace.screen,
            SvaSpace.lg,
            SvaSpace.screen,
            SvaSpace.xl,
          ),
          children: [
            const Align(alignment: Alignment.centerLeft, child: _Wordmark()),
            const SizedBox(height: SvaSpace.md),
            for (final session in sessions) _SessionRow(session: session),
          ],
        ),
      );
    }
    return _TabScreen(
      header: const Align(alignment: Alignment.centerLeft, child: _Wordmark()),
      empty: _EmptyState(
        icon: LucideIcons.mountainSnow,
        title: l10n.feedEmptyTitle,
        body: l10n.feedEmptyBody,
        actionLabel: l10n.logButton,
        onAction: () => context.push(Routes.log),
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const new({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final climbs = ref.watch(sessionAscentsProvider(session.id)).value;
    final weather = ref.watch(sessionWeatherProvider(session.id)).value;
    final weatherText = weather == null ? '' : weatherLine(l10n, weather);
    final day = formatDay(l10n, session.localDate);
    return Padding(
      padding: const EdgeInsets.only(bottom: SvaSpace.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(SvaSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.title ?? day, style: context.svaText.headline),
              const SizedBox(height: SvaSpace.xxs),
              Text(
                [
                  if (session.title != null) day,
                  if (climbs != null) l10n.logClimbCount(climbs.length),
                ].join(' · '),
                style: context.svaText.caption.copyWith(
                  color: context.svaColors.textMuted,
                ),
              ),
              if (weatherText.isNotEmpty)
                Text(
                  weatherText,
                  style: context.svaText.caption.copyWith(
                    color: context.svaColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// History tab. Stats arrive in M6.
class HistoryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _TabScreen(
      header: Row(
        children: [
          Expanded(child: _ScreenTitle(l10n.historyTitle)),
          IconButton(
            tooltip: l10n.routeSearchOpen,
            onPressed: () => context.push(Routes.routeSearch),
            icon: Icon(LucideIcons.search, color: context.svaColors.text),
          ),
        ],
      ),
      empty: _EmptyState(
        icon: LucideIcons.chartLine,
        title: l10n.historyEmptyTitle,
        body: l10n.historyEmptyBody,
        actionLabel: l10n.logButton,
        onAction: () => context.push(Routes.log),
      ),
    );
  }
}

/// Climbing CV tab. The CV arrives in M7.
class CvScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _TabScreen(
      header: _ScreenTitle(l10n.cvTitle),
      empty: _EmptyState(
        icon: LucideIcons.idCard,
        title: l10n.cvEmptyTitle,
        body: l10n.cvEmptyBody,
        actionLabel: l10n.logButton,
        onAction: () => context.push(Routes.log),
      ),
    );
  }
}

/// Training tab. Benchmarks arrive in M10, so there is no action yet.
class TrainingScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _TabScreen(
      header: _ScreenTitle(l10n.trainingTitle),
      empty: _EmptyState(
        icon: LucideIcons.dumbbell,
        title: l10n.trainingEmptyTitle,
        body: l10n.trainingEmptyBody,
      ),
    );
  }
}

class _TabScreen extends StatelessWidget {
  const new({required this.header, required this.empty});

  final Widget header;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SvaSpace.screen,
                      SvaSpace.lg,
                      SvaSpace.screen,
                      SvaSpace.sm,
                    ),
                    child: header,
                  ),
                  // The empty state fills the rest of the screen and scrolls
                  // when large text makes it taller than the screen.
                  Expanded(child: Center(child: empty)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: context.svaText.display),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Sva',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SvaMark(size: 36),
          const SizedBox(width: SvaSpace.xs),
          Text('sva', style: context.svaText.display),
        ],
      ),
    );
  }
}

/// One line saying what will appear here and, where possible, one action
/// to add the first item (docs/DESIGN.md, Components).
class _EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    final text = context.svaText;
    return Padding(
      padding: const EdgeInsets.all(SvaSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: SvaSpace.huge, color: colors.granite),
          const SizedBox(height: SvaSpace.md),
          Text(title, style: text.title, textAlign: TextAlign.center),
          const SizedBox(height: SvaSpace.xs),
          Text(
            body,
            style: text.body.copyWith(color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: SvaSpace.xl),
            // Secondary: the log button in the tab bar is the screen's one
            // primary action (docs/DESIGN.md).
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
