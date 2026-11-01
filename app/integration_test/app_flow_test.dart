import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sva/main.dart' as app;

/// Flows: journeys across screens on a real device or emulator. See
/// docs/TESTING.md, layer 5. Taps go through the same labels screen readers
/// use, so the flows also break if a tab loses its label.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M0-8: app starts and every tab can be opened', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Your sessions show up here'), findsOneWidget);

    const tabs = {
      'History': 'Your history starts with one session',
      'CV': 'Your CV builds itself',
      'Training': 'Track strength and mobility',
      'Feed': 'Your sessions show up here',
    };
    for (final MapEntry(key: tab, value: emptyTitle) in tabs.entries) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
      expect(find.text(emptyTitle), findsOneWidget, reason: tab);
    }

    await tester.tap(find.bySemanticsLabel('Log a session').first);
    await tester.pumpAndSettle();
    expect(find.text('Logging climbs is coming soon.'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Logging climbs is coming soon.'), findsNothing);
  });
}
