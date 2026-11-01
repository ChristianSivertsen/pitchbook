import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/src/icon_licenses.dart';

void main() {
  test('M0-5: the icon licence appears on the licence page', () async {
    registerIconLicenses();
    final texts = <String, String>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        texts[package] = entry.paragraphs.map((p) => p.text).join('\n');
      }
    }
    expect(texts['Lucide'], allOf(contains('ISC'), contains('Feather')));
  });
}
