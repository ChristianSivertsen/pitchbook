import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  test('M0-4: bundled fonts appear on the licence page', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerSvaFontLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, containsAll(['Fraunces', 'Inter']));
  });
}
