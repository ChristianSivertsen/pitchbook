import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root widget. The tab shell (M0-5) and theme tokens (M0-4) replace the
/// placeholder route and default theme.
class PitchbookApp extends StatelessWidget {
  const PitchbookApp({super.key});

  static final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Pitchbook', routerConfig: _router);
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Pitchbook')));
  }
}
