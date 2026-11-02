import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sva/src/places/crag_form_screen.dart';
import 'package:sva/src/places/route_detail_screen.dart';
import 'package:sva/src/places/route_form_screen.dart';
import 'package:sva/src/places/route_search_screen.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva/src/shell/log_sheet.dart';
import 'package:sva/src/shell/not_found_screen.dart';
import 'package:sva/src/shell/tab_screens.dart';
import 'package:sva_ui/sva_ui.dart';

/// The app's router. Lives in a provider so each [ProviderScope] (the app,
/// or a single test) gets its own instance, and so routes can later read
/// other providers, for example to redirect on sign-in state.
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.feed,
    // `/` has no screen of its own; links to it open the feed.
    redirect: (context, state) =>
        state.matchedLocation == '/' ? Routes.feed : null,
    // Unknown or outdated links show a friendly page instead of the raw
    // error, and never echo the link back.
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                builder: (context, state) => const FeedScreen(),
                routes: [
                  // Entry for links and notifications: the sheet opens over
                  // the feed, so closing it always lands on a tab.
                  GoRoute(
                    path: Routes.logLinkSegment,
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) =>
                        LogSheetPage(key: state.pageKey),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: Routes.routeSearchSegment,
                    builder: (context, state) => const RouteSearchScreen(),
                    routes: [
                      GoRoute(
                        path: Routes.newSegment,
                        builder: (context, state) => const RouteFormScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.cragsNewSegment,
                    builder: (context, state) => const CragFormScreen(),
                  ),
                  GoRoute(
                    path: Routes.routeSegment,
                    builder: (context, state) => RouteDetailScreen(
                      routeId: state.pathParameters['routeId']!,
                    ),
                  ),
                ],
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
