import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_ui/sva_ui.dart';

/// The frame around the four tabs: the current tab's screen and the tab bar
/// with the log button in the middle.
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});

  /// The tab navigator from go_router; keeps each tab's state.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _TabBar(
        currentIndex: shell.currentIndex,
        onSelect: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const new({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final tabs = [
      (l10n.tabFeed, LucideIcons.house),
      (l10n.tabHistory, LucideIcons.chartColumn),
      (l10n.tabCv, LucideIcons.circleUser),
      (l10n.tabTraining, LucideIcons.dumbbell),
    ];
    Widget tab(int index) {
      final (label, icon) = tabs[index];
      return Expanded(
        child: _TabButton(
          label: label,
          icon: icon,
          selected: currentIndex == index,
          onTap: () => onSelect(index),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunk,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SvaSpace.xs),
          child: Row(
            children: [
              tab(0),
              tab(1),
              const Expanded(
                child: Center(
                  // Keep the bar only as tall as its content.
                  heightFactor: 1,
                  child: _LogButton(key: logButtonKey),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    final colour = selected ? colors.text : colors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: SvaSpace.xxl,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SvaSpace.minTouchTarget),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colour, size: SvaSpace.xl),
              const SizedBox(height: SvaSpace.xxs),
              Text(
                label,
                style: context.svaText.caption.copyWith(color: colour),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Finds the log button in the tab bar, for tests.
const ValueKey<String> logButtonKey = ValueKey('tab-bar-log-button');

class _LogButton extends StatelessWidget {
  const new({super.key});

  /// Size from docs/DESIGN.md.
  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.svaColors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).logButton,
      onTap: () => context.push(Routes.log),
      excludeSemantics: true,
      child: Material(
        color: colors.sun,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(SvaRadius.logButton),
        ),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(SvaRadius.logButton),
          ),
          onTap: () => context.push(Routes.log),
          child: SizedBox.square(
            dimension: _size,
            child: Icon(
              LucideIcons.plus,
              color: colors.onSun,
              size: SvaSpace.xl,
            ),
          ),
        ),
      ),
    );
  }
}
