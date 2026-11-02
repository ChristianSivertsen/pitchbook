import 'dart:convert';
import 'dart:io';

import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

/// The shared cases, also run by the server from M11-2. Found from the
/// package folder or the repository root.
Map<String, Object?> _load() {
  final file = [
    '../../shared/test_cases/name_keys.json',
    'shared/test_cases/name_keys.json',
  ].map(File.new).firstWhere((f) => f.existsSync());
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  final data = _load();
  final cases = (data['cases']! as List<Object?>).cast<Map<String, Object?>>();

  group('M2-1: shared name key cases', () {
    for (final c in cases) {
      final name = c['name']! as String;
      test('"$name"', () {
        expect(searchKey(name), c['search']);
        expect(asciiKey(name), c['ascii']);
      });
    }
  });

  test('M2-1: names sort with æ, ø and å after z', () {
    final order = (data['order']! as List<Object?>).cast<String>();
    final shuffled = [...order.reversed]..sort(compareNames);
    // "Aaland" sorts as "Åland", before "Åsane".
    expect(shuffled, order);
  });
}
