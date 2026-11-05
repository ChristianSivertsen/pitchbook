/// One climb as the session totals see it: its route's pitches and
/// length.
typedef ClimbSize = ({int pitchCount, double? lengthM});

/// A session's pitches and metres climbed. A route climbed twice counts
/// twice. The metres are `null` when any route's length is unknown, or the
/// session has no climbs, so a partial sum never passes for the total.
({int pitches, double? metres}) sessionTotals(Iterable<ClimbSize> climbs) {
  var pitches = 0;
  var metres = climbs.isEmpty ? null : 0.0;
  for (final climb in climbs) {
    pitches += climb.pitchCount;
    metres = switch ((metres, climb.lengthM)) {
      (final sum?, final length?) => sum + length,
      _ => null,
    };
  }
  return (pitches: pitches, metres: metres);
}
