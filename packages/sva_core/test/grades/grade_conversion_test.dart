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

  test('M1-3: round trips between systems land within one step', () {
    for (final from in gradeSystems) {
      for (final to in gradeSystems.where(
        (s) => s.gradeType == from.gradeType,
      )) {
        // Grades beyond the other system's ends clamp; the edge-grade test
        // covers those.
        final covered = from.grades.where(
          (g) =>
              g.scoreHigh >= to.grades.first.scoreLow &&
              g.scoreLow <= to.grades.last.scoreHigh,
        );
        for (final grade in covered) {
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
    expect(convert('VII', uiaa, french), '6b');
    expect(convert('X', uiaa, french), '8b');
    expect(convert('XI', uiaa, french), '9a');
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
    const empty = GradeSystem(
      key: 'empty',
      name: 'Empty',
      gradeType: 'free_route',
      grades: [],
    );
    expect(convert('7a', french, empty), isNull);
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
    expect(convert('6a/6a+', french, uiaa), 'VI+', reason: 'tie: easier');
    expect(norwegian.parse('8-/7+'), isNull, reason: 'harder grade first');
    expect(norwegian.parse('7/x'), isNull);
  });

  test('M1-3: changing the display system never changes stored grades', () {
    // Screens keep the grade as logged and only convert to display it. For
    // every grade: shown in its own system it is exactly what was logged,
    // and showing it in any other system leaves that grade unchanged.
    for (final logged in gradeSystems) {
      for (final grade in logged.grades) {
        final before = logged.parse(grade.label)!;
        for (final display in gradeSystems) {
          convertGrade(grade.label, logged, display);
        }
        final after = convertGrade(grade.label, logged, logged)!;
        expect(
          (after.label, after.scoreLow, after.scoreHigh),
          (before.label, before.scoreLow, before.scoreHigh),
          reason: '${logged.key} ${grade.label}',
        );
        expect(
          identical(
            logged.grades.firstWhere((g) => g.label == grade.label),
            grade,
          ),
          isTrue,
        );
      }
    }
    expect(convert('7+/8-', norwegian, norwegian), '7+/8-');
  });

  test('M1-3: only well-formed grade lists are valid', () {
    for (final system in gradeSystems) {
      expect(isValidGradeList(system.grades), isTrue, reason: system.key);
    }
    expect(isValidGradeList([]), isFalse);
    expect(
      isValidGradeList([const Grade('a', 2), const Grade('b', 1)]),
      isFalse,
    );
    expect(
      isValidGradeList([const Grade('a', 1), const Grade('a', 2)]),
      isFalse,
    );
    expect(isValidGradeList([const Grade.range('a', 2, 1)]), isFalse);
    expect(
      isValidGradeList([const Grade.range('a', 1, 3), const Grade('b', 2)]),
      isFalse,
    );
    expect(isValidGradeList([const Grade('a', double.nan)]), isFalse);
  });
}
