import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva/src/shell/log_sheet.dart';
import 'package:sva/src/shell/tab_screens.dart';
import 'package:sva_ui/sva_ui.dart';

/// The app's router. Lives in a provider so each [ProviderScope] (the app,
/// or a single test) gets its own instance, and so routes can later read
/// other providers, for example to redirect on sign-in state.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.feed,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.cv,
                builder: (context, state) => const CvScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.training,
                builder: (context, state) => const TrainingScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.log,
        pageBuilder: (context, state) => LogSheetPage(key: state.pageKey),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.tokenPreview,
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: SvaTokenPreview())),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
