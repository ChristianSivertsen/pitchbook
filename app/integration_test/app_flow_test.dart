import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/main.dart' as app;
import 'package:sva/src/shell/app_shell.dart';

/// Flows: journeys across screens on a real device or emulator. See
/// docs/TESTING.md, layer 5. Texts come from the app's translations, so
/// flows pass whatever language the device uses. Taps go through the same
/// labels screen readers use, so a flow also breaks if a tab loses its label.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M0-8: app starts and every tab can be opened', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(AppShell)));
    expect(find.text(l10n.feedEmptyTitle), findsOneWidget);

    final tabs = {
      l10n.tabHistory: l10n.historyEmptyTitle,
      l10n.tabCv: l10n.cvEmptyTitle,
      l10n.tabTraining: l10n.trainingEmptyTitle,
      l10n.tabFeed: l10n.feedEmptyTitle,
    };
    for (final MapEntry(key: tab, value: emptyTitle) in tabs.entries) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
      expect(find.text(emptyTitle), findsOneWidget, reason: tab);
    }
  });
}
