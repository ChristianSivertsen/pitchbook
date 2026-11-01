import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitchbook/src/app.dart';

void main() {
  testWidgets('app starts and shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PitchbookApp()));
    await tester.pumpAndSettle();

    expect(find.text('Pitchbook'), findsOneWidget);
  });
}
