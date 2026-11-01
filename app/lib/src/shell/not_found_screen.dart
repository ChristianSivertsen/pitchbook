import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_ui/sva_ui.dart';

/// Shown for links the app does not know. It does not repeat the link,
/// since links can later carry IDs.
class NotFoundScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final text = context.svaText;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SvaSpace.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mapPinOff,
                  size: SvaSpace.huge,
                  color: colors.granite,
                ),
                const SizedBox(height: SvaSpace.md),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.notFoundTitle,
                    style: text.title,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: SvaSpace.xs),
                Text(
                  l10n.notFoundBody,
                  style: text.body.copyWith(color: colors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SvaSpace.xl),
                FilledButton(
                  onPressed: () => context.go(Routes.feed),
                  child: Text(l10n.notFoundAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
