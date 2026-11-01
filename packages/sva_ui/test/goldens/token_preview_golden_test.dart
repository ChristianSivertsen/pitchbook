import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:sva_ui/sva_ui.dart';

Future<void> main() async {
  Widget preview(ThemeData theme) => Theme(
    data: theme,
    child: Material(
      color: theme.scaffoldBackgroundColor,
      child: const SizedBox(width: 420, height: 980, child: SvaTokenPreview()),
    ),
  );

  await goldenTest(
    'M0-4: token preview in both themes',
    fileName: 'token_preview',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'Midnight sun',
          child: preview(SvaTheme.midnight()),
        ),
        GoldenTestScenario(
          name: 'Daylight',
          child: preview(SvaTheme.daylight()),
        ),
      ],
    ),
  );
}
