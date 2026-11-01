import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';
import 'package:sva/src/shell/app_shell.dart';
import 'package:sva/src/shell/log_sheet.dart';
import 'package:sva/src/shell/tab_screens.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  late ProviderContainer container;

  Future<void> startApp(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('M0-5: the app opens on the feed', (tester) async {
    await startApp(tester);
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.text('Your sessions show up here'), findsOneWidget);
  });

  testWidgets('M0-5: every tab is reachable and shows its empty state', (
    tester,
  ) async {
    await startApp(tester);
    final tabs = {
      'History': ('Your history starts with one session', HistoryScreen),
      'CV': ('Your CV builds itself', CvScreen),
      'Training': ('Track strength and mobility', TrainingScreen),
      'Feed': ('Your sessions show up here', FeedScreen),
    };
    for (final MapEntry(key: tab, value: (emptyTitle, screen))
        in tabs.entries) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: tab);
      expect(find.text(emptyTitle), findsOneWidget, reason: tab);
    }
  });

  testWidgets('M0-5: screen readers read each tab and the log button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await startApp(tester);
    for (final label in ['Feed', 'History', 'CV', 'Training']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: label == 'Feed',
        ),
        reason: label,
      );
    }
    expect(
      tester.getSemantics(find.byKey(logButtonKey)),
      matchesSemantics(
        label: 'Log a session',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('M0-5: the log button opens the log sheet and close shuts it', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.byKey(logButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(LogSheet), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(LogSheet), findsNothing);
    expect(find.byType(FeedScreen), findsOneWidget);
  });

  testWidgets('M0-5: deep links open the right tab and the log sheet', (
    tester,
  ) async {
    await startApp(tester);
    container.read(routerProvider).go(Routes.cv);
    await tester.pumpAndSettle();
    expect(find.byType(CvScreen), findsOneWidget);

    container.read(routerProvider).go(Routes.log);
    await tester.pumpAndSettle();
    expect(find.byType(LogSheet), findsOneWidget);
  });

  testWidgets('M0-5: an empty state action opens the log sheet', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log a session'));
    await tester.pumpAndSettle();
    expect(find.byType(LogSheet), findsOneWidget);
  });

  testWidgets('M0-5: the tab bar sits at the bottom of the screen', (
    tester,
  ) async {
    await startApp(tester);
    final screen = tester.getRect(find.byType(AppShell));
    final log = tester.getRect(find.byKey(logButtonKey));
    expect(screen.bottom - log.bottom, lessThan(SvaSpace.huge));
  });
}
