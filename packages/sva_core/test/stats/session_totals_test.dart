import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

void main() {
  test('M2-7: a session totals its pitches and metres', () {
    final totals = sessionTotals([
      (pitchCount: 1, lengthM: 20),
      (pitchCount: 3, lengthM: 95.5),
      (pitchCount: 1, lengthM: 20),
    ]);
    expect(totals.pitches, 5);
    expect(totals.metres, 135.5);

    // One route without a length makes the total unknown, not too low.
    final partly = sessionTotals([
      (pitchCount: 2, lengthM: 40),
      (pitchCount: 1, lengthM: null),
    ]);
    expect(partly.pitches, 3);
    expect(partly.metres, isNull);

    final empty = sessionTotals(const []);
    expect(empty.pitches, 0);
    expect(empty.metres, isNull);
  });
}
