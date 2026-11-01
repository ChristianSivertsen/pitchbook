import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_ui/sva_ui.dart';

/// The log sheet as a page, so `/log` works as a deep link and the system
/// back gesture closes it. Slides up over the current tab.
class LogSheetPage extends CustomTransitionPage<void> {
  new({super.key})
    : super(
        child: const LogSheet(),
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: SvaColors.scrim,
        transitionDuration: SvaMotion.sheet,
        reverseTransitionDuration: SvaMotion.sheet,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          if (reduced) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: SvaMotion.easeOut,
            reverseCurve: SvaMotion.easeIn,
          );
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );
}

/// Closes the sheet. If it was opened as the first page (an old link to
/// `/log`), there is nothing to go back to, so it opens the feed instead.
void closeLogSheet(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.feed);
  }
}

/// The log sheet. Logging itself arrives in M2-3.
class LogSheet extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final text = context.svaText;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: colors.surface,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: SvaRadius.sheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SvaSpace.xs,
                    SvaSpace.xs,
                    SvaSpace.screen,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () => closeLogSheet(context),
                        icon: Icon(LucideIcons.x, color: colors.text),
                      ),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.logSheetTitle,
                            style: text.title,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: SvaSpace.minTouchTarget),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(SvaSpace.xxl),
                  child: Text(
                    l10n.logSheetBody,
                    style: text.body.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
