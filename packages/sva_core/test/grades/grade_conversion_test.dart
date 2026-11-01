import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

void main() {
  String? convert(String label, GradeSystem from, GradeSystem to) =>
      convertGrade(label, from, to)?.label;

  test('M1-3: every grade converts to the shared score and back', () {
    for (final system in gradeSystems) {
      final grades = system.grades;
      for (var i = 0; i < grades.length; i++) {
        final grade = grades[i];
        expect(
          system.nearest(grade.score).label,
          grade.label,
          reason: '${system.key} ${grade.label}',
        );
        expect(system.parse(grade.label)?.label, grade.label);
        if (i > 0) {
          expect(
            grade.scoreLow,
            greaterThan(grades[i - 1].scoreHigh),
            reason: '${system.key} ${grade.label} must be harder than the last',
          );
        }
      }
      expect(grades.map((g) => g.label).toSet(), hasLength(grades.length));
    }
    expect(gradeSystems.map((s) => s.key).toSet(), {
      'nor',
      'french',
      'yds',
      'uiaa',
      'font',
      'v',
    });
  });

  test('M1-3: round trips between systems land within one grade step', () {
    for (final from in gradeSystems) {
      for (final to in gradeSystems.where(
        (s) => s.gradeType == from.gradeType,
      )) {
        for (final grade in from.grades) {
          final there = convertGrade(grade.label, from, to)!;
          final back = convertGrade(there.label, to, from)!;
          expect(
            (back.score - grade.score).abs(),
            lessThanOrEqualTo(1),
            reason:
                '${from.key} ${grade.label} → ${to.key} ${there.label} → '
                '${back.label}',
          );
        }
      }
    }
    // Some well-known pairs.
    expect(convert('7', norwegian, french), '6c');
    expect(convert('8', norwegian, french), '7b');
    expect(convert('6a', french, norwegian), '6-');
    expect(convert('7a', french, yds), '5.11d');
    expect(convert('5.12a', yds, french), '7a+');
    expect(convert('VII', uiaa, french), '6b+');
    expect(convert('7A', font, vScale), 'V6');
  });

  test('M1-3: edge grades convert to the nearest end and never fail', () {
    for (final system in gradeSystems) {
      expect(system.nearest(-100).label, system.grades.first.label);
      expect(system.nearest(100).label, system.grades.last.label);
    }
    expect(convert('9c', french, norwegian), '11+');
    expect(convert('3', french, yds), '5.4', reason: 'below YDS 5.4');
    expect(convert('9A', font, vScale), 'V17');
    expect(convert('7z', french, norwegian), isNull, reason: 'unknown grade');
    expect(convert('7a', french, font), isNull, reason: 'routes ≠ boulders');
    expect(convert(' 7- ', norwegian, norwegian), '7-', reason: 'trimmed');
    // On an exact tie the easier grade wins, so conversions never flatter.
    expect(vScale.nearest(13.25).label, 'V1');
  });

  test('M1-3: range grades cover every grade they span', () {
    expect(convert('6A', font, vScale), 'V3');
    expect(convert('6A+', font, vScale), 'V3');
    expect(convert('6c+', french, norwegian), '7+');
    expect(convert('7a', french, norwegian), '7+');
    expect(convert('V3', vScale, font), '6A', reason: 'midpoint tie: easier');

    final slash = norwegian.parse('7+/8-')!;
    expect((slash.scoreLow, slash.scoreHigh, slash.score), (20.0, 22.0, 21.0));
    expect(convert('7+/8-', norwegian, french), '7a');
    expect(convert('6a/6a+', french, uiaa), 'VI', reason: 'tie: easier');
    expect(norwegian.parse('8-/7+'), isNull, reason: 'harder grade first');
    expect(norwegian.parse('7/x'), isNull);
  });

  test('M1-3: changing the display system never changes stored grades', () {
    // An ascent stores the grade as logged: its system and label.
    const stored = (system: 'nor', label: '7+/8-');
    final logged = gradeSystems.firstWhere((s) => s.key == stored.system);

    for (final display in gradeSystems.where(
      (s) => s.gradeType == logged.gradeType,
    )) {
      convertGrade(stored.label, logged, display);
    }

    expect(stored, (system: 'nor', label: '7+/8-'));
    expect(
      convert(stored.label, logged, norwegian),
      '7+/8-',
      reason: 'shown in its own system it is exactly what was logged',
    );
  });
}
