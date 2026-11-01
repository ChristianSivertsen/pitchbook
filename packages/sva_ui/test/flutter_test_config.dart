import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Golden tests use platform-independent "CI" goldens only, so the same
/// images pass on macOS and on the Linux CI runner.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
