import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The app's router. Lives in a provider so each [ProviderScope] (the app,
/// or a single test) gets its own instance, and so routes can later read
/// other providers, for example to redirect on sign-in state.
///
/// The tab shell (M0-5) replaces the placeholder route.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _PlaceholderScreen extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('sva')));
  }
}
