/// One grade in a system, placed on the shared difficulty scale.
///
/// Scores are comparable only within a grade type (free routes with free
/// routes, boulders with boulders). A grade that covers a span of the other
/// systems, such as V3 or a Norwegian 7+, has [scoreLow] and [scoreHigh];
/// [score] is then the middle.
final class Grade {
  const new(this.label, this.score) : scoreLow = score, scoreHigh = score;

  /// A grade spanning [low] to [high] on the shared scale.
  const new range(this.label, double low, double high)
    : scoreLow = low,
      scoreHigh = high,
      score = (low + high) / 2;

  /// As written in its system, for example `7-`, `6c+` or `V3`.
  final String label;
  final double score;
  final double scoreLow;
  final double scoreHigh;

  /// How far [value] is from this grade: zero anywhere inside its span.
  double distanceTo(double value) {
    if (value < scoreLow) return scoreLow - value;
    if (value > scoreHigh) return value - scoreHigh;
    return 0;
  }

  @override
  String toString() => 'Grade($label, $score)';
}

/// A grading system such as Norwegian, French or Font, stored as data so
/// new local systems need no code (docs/schema.md, grade_systems).
final class GradeSystem {
  const new({
    required this.key,
    required this.name,
    required this.gradeType,
    required this.grades,
    this.region,
  });

  /// Stable key, for example `nor`.
  final String key;

  /// English name for logs and tests; screens use translations.
  final String name;

  /// `free_route` or `boulder` (more types come with ice and alpine).
  final String gradeType;

  /// Easiest first. Scores rise strictly through the list.
  final List<Grade> grades;
  final String? region;

  /// The grade written as [label], or `null` when this system has none.
  ///
  /// A slash grade between two neighbours, such as `7+/8-` or `6a/6a+`,
  /// becomes a range from the first to the second.
  Grade? parse(String label) {
    final text = label.trim();
    for (final grade in grades) {
      if (grade.label == text) return grade;
    }
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final from = parse(parts[0]);
    final to = parse(parts[1]);
    if (from == null || to == null || to.score <= from.score) return null;
    return Grade.range(text, from.scoreLow, to.scoreHigh);
  }

  /// The grade in this system nearest to [score]. Beyond either end of the
  /// list it is the easiest or the hardest grade. On a tie the easier grade
  /// wins, so a conversion never flatters.
  Grade nearest(double score) {
    var best = grades.first;
    for (final grade in grades.skip(1)) {
      if (grade.distanceTo(score) < best.distanceTo(score)) best = grade;
    }
    return best;
  }
}

/// Shows a stored grade in another system. The stored grade itself never
/// changes: screens keep the original label and system, and call this only
/// to display it.
///
/// Returns `null` when [label] is not a grade in [from], or the two systems
/// grade different things.
Grade? convertGrade(String label, GradeSystem from, GradeSystem to) {
  if (from.gradeType != to.gradeType) return null;
  final grade = from.parse(label);
  if (grade == null) return null;
  if (identical(from, to) || from.key == to.key) return grade;
  return to.nearest(grade.score);
}
