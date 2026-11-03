/// How a climb went (docs/schema.md, ascents.style).
enum AscentStyle {
  /// First try, no prior information.
  onsight,

  /// First try, with beta.
  flash,

  /// First send after earlier tries.
  redpoint,

  /// A send of a route already sent.
  repeat,

  /// No send.
  attempt;

  /// Whether this style counts as a send.
  bool get isSend => this != attempt;
}

/// One logged climb of a route, as the rules see it.
typedef LoggedAscent = ({AscentStyle style, int tries});

/// A broken rule, as a stable key for translations and the server.
enum AscentIssue {
  /// Onsight or flash after the route was tried or sent before.
  notFirstTry('style.not_first_try'),

  /// Onsight is for outdoor rope climbs; boulders and gym climbs flash.
  noOnsight('style.no_onsight'),

  /// Onsight, flash or redpoint of a route already sent: it is a repeat.
  alreadySent('style.already_sent'),

  /// A repeat of a route that was never sent.
  repeatWithoutSend('style.repeat_without_send'),

  /// Onsight and flash are exactly one try.
  mustBeOneTry('tries.must_be_one'),

  /// Too few tries for the style, counting earlier attempts.
  tooFewTries('tries.too_few'),

  /// More tries than anyone logs: [maxLoggedTries].
  tooManyTries('tries.too_many');

  new(this.key);

  /// For example `tries.too_few`.
  final String key;
}

/// A sanity limit on tries in one ascent, so a typo cannot break the sums.
/// The server applies the same limit.
const maxLoggedTries = 9999;

/// What earlier ascents of the same route mean for the next one.
final class RouteHistory {
  /// History from [earlier] ascents of one route, oldest first. Gym routes
  /// follow the same rules, and tries add up across sessions (PLAN.md 4, 7),
  /// except that only outdoor rope climbs can be onsighted: boulders and
  /// gym climbs are usually seen up close first, so they flash.
  factory from(
    Iterable<LoggedAscent> earlier, {
    bool boulder = false,
    bool gym = false,
  }) {
    var tries = 0;
    var sent = false;
    for (final ascent in earlier) {
      if (ascent.style.isSend) {
        sent = true;
      } else if (!sent) {
        // An attempt always counts as at least one try, and never more
        // than the limit, even when its own count is flagged as wrong.
        tries += ascent.tries.clamp(1, maxLoggedTries);
      }
    }
    return RouteHistory._(
      earlierTries: tries,
      sent: sent,
      onsightPossible: !boulder && !gym,
    );
  }

  const new _({
    required this.earlierTries,
    required this.sent,
    required this.onsightPossible,
  });

  /// Tries on attempts before the first send. Any logged attempt counts as
  /// at least one, so it is above zero whenever the route was tried.
  final int earlierTries;

  /// Whether the route was sent before.
  final bool sent;

  /// Whether this kind of route can be onsighted at all.
  final bool onsightPossible;

  /// Styles a new ascent may have. Once sent, only repeats and attempts.
  /// After an attempt, no onsight or flash.
  Set<AscentStyle> get allowedStyles => sent
      ? {AscentStyle.repeat, AscentStyle.attempt}
      : earlierTries > 0
      ? {AscentStyle.redpoint, AscentStyle.attempt}
      : {
          if (onsightPossible) AscentStyle.onsight,
          AscentStyle.flash,
          AscentStyle.redpoint,
          AscentStyle.attempt,
        };

  /// The fewest tries an ascent in [style] can log. A redpoint counts the
  /// earlier attempts and needs at least 2 (it followed a fall or a rest).
  int minTries(AscentStyle style) => switch (style) {
    AscentStyle.redpoint => earlierTries + 1 < 2 ? 2 : earlierTries + 1,
    _ => 1,
  };

  /// The most tries: onsight and flash are 1, everything else is capped
  /// at [maxLoggedTries].
  int maxTries(AscentStyle style) => switch (style) {
    AscentStyle.onsight || AscentStyle.flash => 1,
    _ => maxLoggedTries,
  };

  /// What is wrong with logging [ascent] after this history.
  List<AscentIssue> check(LoggedAscent ascent) {
    final style = ascent.style;
    return [
      if (sent && style.isSend && style != AscentStyle.repeat)
        AscentIssue.alreadySent
      else if (!sent && earlierTries > 0 && _firstTry(style))
        AscentIssue.notFirstTry,
      if (style == AscentStyle.onsight && !onsightPossible)
        AscentIssue.noOnsight,
      if (style == AscentStyle.repeat && !sent) AscentIssue.repeatWithoutSend,
      if (_firstTry(style) && ascent.tries != 1)
        AscentIssue.mustBeOneTry
      else if (ascent.tries < minTries(style))
        AscentIssue.tooFewTries
      else if (ascent.tries > maxTries(style))
        AscentIssue.tooManyTries,
    ];
  }

  static bool _firstTry(AscentStyle style) =>
      style == AscentStyle.onsight || style == AscentStyle.flash;
}

/// Checks every ascent of one route in order, oldest first (by the
/// session's local date, then the ascent's ordinal), against what
/// came before it. Run it again after an edit (an ascent added, changed or
/// removed): earlier attempts that disappear can make a later onsight
/// possible, and a removed send turns a later repeat into an issue.
List<List<AscentIssue>> checkRouteLog(
  List<LoggedAscent> ascents, {
  bool boulder = false,
  bool gym = false,
}) => [
  for (var i = 0; i < ascents.length; i++)
    RouteHistory.from(
      ascents.take(i),
      boulder: boulder,
      gym: gym,
    ).check(ascents[i]),
];

/// One route's log after an edit, oldest first, with the first send's
/// tries recounted. A redpoint's tries include the attempts before it, so
/// when attempts before it are added or removed, its tries move by the
/// same number, never below the fewest a redpoint can log. [before] and
/// [after] are the log before and after the edit, each ascent with a key
/// that identifies it in both.
List<LoggedAscent> recountTries<K>(
  List<(K, LoggedAscent)> before,
  List<(K, LoggedAscent)> after, {
  bool boulder = false,
  bool gym = false,
}) {
  final result = [for (final (_, ascent) in after) ascent];
  final old = _firstSend(before);
  final now = _firstSend(after);
  if (old == null || now == null) return result;
  final (oldIndex, oldEarlier) = old;
  final (newIndex, newEarlier) = now;
  final (oldKey, ascent) = before[oldIndex];
  if (after[newIndex].$1 != oldKey || ascent.style != AscentStyle.redpoint) {
    return result;
  }
  final own = ascent.tries - oldEarlier;
  final min = RouteHistory.from(
    result.take(newIndex),
    boulder: boulder,
    gym: gym,
  ).minTries(AscentStyle.redpoint);
  final tries = (newEarlier + own).clamp(min, maxLoggedTries);
  result[newIndex] = (style: ascent.style, tries: tries);
  return result;
}

/// Where the first send is in [log] and the tries on attempts before it.
(int, int)? _firstSend<K>(List<(K, LoggedAscent)> log) {
  for (var i = 0; i < log.length; i++) {
    if (log[i].$2.style.isSend) {
      final earlier = RouteHistory.from([for (final (_, a) in log.take(i)) a])
          .earlierTries;
      return (i, earlier);
    }
  }
  return null;
}
