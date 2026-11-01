import 'dart:convert';
import 'dart:io';

import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

/// The shared cases, also run by the server from M11-2. Found from the
/// package folder or the repository root.
Map<String, Object?> _load() {
  final file = [
    '../../shared/test_cases/ascent_rules.json',
    'shared/test_cases/ascent_rules.json',
  ].map(File.new).firstWhere((f) => f.existsSync());
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

AscentStyle _style(Object? name) => AscentStyle.values.byName(name! as String);

void main() {
  final cases = (_load()['cases']! as List<Object?>)
      .cast<Map<String, Object?>>();

  List<LoggedAscent> logOf(Map<String, Object?> c) => [
    for (final entry in (c['log']! as List<Object?>).cast<List<Object?>>())
      (style: _style(entry[0]), tries: entry[1]! as int),
  ];

  group('M1-4: shared style and tries cases', () {
    for (final c in cases.where((c) => c.containsKey('expect'))) {
      test(c['name']! as String, () {
        final removed = ((c['remove'] as List<Object?>?) ?? const [])
            .cast<int>()
            .toSet();
        final log = [
          for (final (i, ascent) in logOf(c).indexed)
            if (!removed.contains(i)) ascent,
        ];
        final issues = checkRouteLog(log);
        expect(
          [for (final list in issues) list.map((i) => i.key).toList()],
          [
            for (final list in (c['expect']! as List<Object?>))
              (list! as List<Object?>).cast<String>(),
          ],
        );
      });
    }

    for (final c in cases.where((c) => c.containsKey('next'))) {
      test(c['name']! as String, () {
        final next = c['next']! as Map<String, Object?>;
        final history = RouteHistory.from(logOf(c));
        expect(
          history.allowedStyles,
          (next['allowed']! as List<Object?>).map(_style).toSet(),
        );
        final minTries = next['min_tries']! as Map<String, Object?>;
        for (final MapEntry(:key, :value) in minTries.entries) {
          expect(history.minTries(_style(key)), value, reason: key);
        }
        final maxTries =
            (next['max_tries'] as Map<String, Object?>?) ?? const {};
        for (final MapEntry(:key, :value) in maxTries.entries) {
          expect(history.maxTries(_style(key)), value, reason: key);
        }
      });
    }
  });

  test('M1-4: the shared cases cover every rule and issue', () {
    final expected = {
      for (final c in cases)
        for (final list in (c['expect'] as List<Object?>?) ?? const [])
          ...(list! as List<Object?>).cast<String>(),
    };
    expect(expected, AscentIssue.values.map((i) => i.key).toSet());
    expect(cases.where((c) => c.containsKey('remove')), hasLength(4));
    expect(cases.where((c) => c['gym'] == true), isNotEmpty);
  });
}
