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

  /// Onsight, flash or redpoint of a route already sent: it is a repeat.
  alreadySent('style.already_sent'),

  /// A repeat of a route that was never sent.
  repeatWithoutSend('style.repeat_without_send'),

  /// Onsight and flash are exactly one try.
  mustBeOneTry('tries.must_be_one'),

  /// Too few tries for the style, counting earlier attempts.
  tooFewTries('tries.too_few');

  new(this.key);

  /// For example `tries.too_few`.
  final String key;
}

/// What earlier ascents of the same route mean for the next one.
final class RouteHistory {
  /// History from [earlier] ascents of one route, oldest first. Gym routes
  /// follow the same rules: tries add up across sessions (PLAN.md 4, 7).
  factory from(Iterable<LoggedAscent> earlier) {
    var tries = 0;
    var sent = false;
    for (final ascent in earlier) {
      if (ascent.style.isSend) {
        sent = true;
      } else if (!sent) {
        tries += ascent.tries;
      }
    }
    return RouteHistory._(earlierTries: tries, sent: sent);
  }

  const new _({required this.earlierTries, required this.sent});

  /// Tries on attempts before the first send.
  final int earlierTries;

  /// Whether the route was sent before.
  final bool sent;

  /// Styles a new ascent may have. Once sent, only repeats and attempts.
  /// After an attempt, no onsight or flash.
  Set<AscentStyle> get allowedStyles => sent
      ? {AscentStyle.repeat, AscentStyle.attempt}
      : earlierTries > 0
      ? {AscentStyle.redpoint, AscentStyle.attempt}
      : {
          AscentStyle.onsight,
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

  /// The most tries, or `null` for no limit: onsight and flash are 1.
  int? maxTries(AscentStyle style) => switch (style) {
    AscentStyle.onsight || AscentStyle.flash => 1,
    _ => null,
  };

  /// What is wrong with logging [ascent] after this history.
  List<AscentIssue> check(LoggedAscent ascent) {
    final style = ascent.style;
    return [
      if (sent && style.isSend && style != AscentStyle.repeat)
        AscentIssue.alreadySent
      else if (!sent && earlierTries > 0 && _firstTry(style))
        AscentIssue.notFirstTry,
      if (style == AscentStyle.repeat && !sent) AscentIssue.repeatWithoutSend,
      if (_firstTry(style) && ascent.tries != 1)
        AscentIssue.mustBeOneTry
      else if (ascent.tries < minTries(style))
        AscentIssue.tooFewTries,
    ];
  }

  static bool _firstTry(AscentStyle style) =>
      style == AscentStyle.onsight || style == AscentStyle.flash;
}

/// Checks every ascent of one route in order, oldest first, against what
/// came before it. Run it again after an edit (an ascent added, changed or
/// removed): earlier attempts that disappear can make a later onsight
/// possible, and a removed send turns a later repeat into an issue.
List<List<AscentIssue>> checkRouteLog(List<LoggedAscent> ascents) => [
  for (var i = 0; i < ascents.length; i++)
    RouteHistory.from(ascents.take(i)).check(ascents[i]),
];
