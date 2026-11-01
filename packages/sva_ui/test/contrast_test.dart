import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  group('contrastRatio', () {
    test('M0-4: black on white is 21 to 1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('M0-4: a colour against itself is 1 to 1', () {
      const grey = Color(0xFF777777);
      expect(contrastRatio(grey, grey), closeTo(1, 0.0001));
    });

    test('M0-4: order of the two colours does not matter', () {
      const a = Color(0xFF1B2240);
      const b = Color(0xFFF7E7CE);
      expect(contrastRatio(a, b), contrastRatio(b, a));
    });

    test('M0-4: matches a known WCAG reference value', () {
      // #767676 on white is the classic 4.54 : 1 AA boundary example.
      expect(
        contrastRatio(const Color(0xFF767676), const Color(0xFFFFFFFF)),
        closeTo(4.54, 0.01),
      );
    });
  });
}
