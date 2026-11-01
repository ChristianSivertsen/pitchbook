import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/theme_mode.dart';
import 'package:sva_ui/sva_ui.dart';

/// Root widget: the Sva themes, following the system or the user's choice.
class SvaApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sva',
      theme: SvaTheme.daylight(),
      darkTheme: SvaTheme.midnight(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
