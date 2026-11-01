import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Root widget. The theme tokens (M0-4) replace the default theme.
class PitchbookApp extends ConsumerWidget {
  const PitchbookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Pitchbook',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
