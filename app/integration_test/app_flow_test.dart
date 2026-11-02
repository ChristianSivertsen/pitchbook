import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/main.dart' as app;
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva/src/shell/tab_screens.dart';

/// Flows: journeys across screens on a real device or emulator. See
/// docs/TESTING.md, layer 5. Texts come from the app's translations, so
/// flows pass whatever language the device uses. Taps go through the same
/// labels screen readers use, so a flow also breaks if a tab loses its label.
/// Debug builds start with the example data (M1-5).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M0-8: app starts and every tab can be opened', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(AppShell)));
    expect(find.byType(FeedScreen), findsOneWidget);

    final tabs = {
      l10n.tabHistory: HistoryScreen,
      l10n.tabCv: CvScreen,
      l10n.tabTraining: TrainingScreen,
      l10n.tabFeed: FeedScreen,
    };
    for (final MapEntry(key: tab, value: screen) in tabs.entries) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: tab);
    }
  });

  testWidgets('M2-3: log an outdoor session with two climbs, see it in the '
      'feed', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(AppShell)));
    final title = 'Flow ${DateTime.now().millisecondsSinceEpoch}';

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tap(find.byKey(logButtonKey));
    final outdoor = find.text(l10n.logOutdoor);
    await tap(outdoor);
    // Attempts are always allowed, whatever the example history holds.
    for (var i = 0; i < 2; i++) {
      await tap(find.text('Hjemmebane').first);
      await tap(find.text(l10n.ascentStyle('attempt')));
      if (i == 0) await tap(find.text(l10n.logAddClimb));
    }
    final titleField = find.widgetWithText(TextField, l10n.logTitle);
    await tester.ensureVisible(titleField);
    await tester.enterText(titleField, title);
    await tester.pumpAndSettle();
    await tap(find.text(l10n.logSave(2)));

    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.text(title), findsOneWidget);
  });
}
