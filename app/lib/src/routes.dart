/// Every path in the app, in one place. Share links and notifications open
/// these paths, so they are part of the app's public interface: change them
/// only with a redirect from the old path.
///
/// Planned paths that later tickets add under the same scheme:
/// - `/cv/rack/:pieceId`, `/cv/shoes/:shoeId` for gear details
/// - `/training/:benchmarkId` for a benchmark
/// - `/people/:userId` for a climber's profile
abstract final class Routes {
  static const feed = '/feed';
  static const history = '/history';
  static const cv = '/cv';
  static const training = '/training';

  /// Route search, from the History tab.
  static const routeSearch = '$history/$routeSearchSegment';
  static const routeSearchSegment = 'routes';

  /// The form for a new route, and for a new crag from inside it.
  static const routeNew = '$routeSearch/$newSegment';
  static const cragNew = '$history/crags/$newSegment';
  static const newSegment = 'new';
  static const cragsNewSegment = 'crags/$newSegment';

  /// One route. Share links open it, so the id is checked by the screen.
  static String route(String routeId) =>
      '$history/route/${Uri.encodeComponent(routeId)}';
  static const routeSegment = 'route/:routeId';

  /// One session. Share links and notifications open it, so the id is
  /// checked by the screen.
  static String session(String sessionId) =>
      '$feed/session/${Uri.encodeComponent(sessionId)}';
  static const sessionSegment = 'session/:sessionId';

  /// The log sheet editing one session, over the session page.
  static String sessionEdit(String sessionId) =>
      '${session(sessionId)}/$editSegment';
  static const editSegment = 'edit';

  /// The log sheet, opened from inside the app with `push`. Opens over
  /// whichever tab is showing.
  static const log = '/log';

  /// The log sheet for links and notifications: opens over the feed.
  static const logLink = '$feed/$logLinkSegment';

  /// Path segment of [logLink] below [feed].
  static const logLinkSegment = 'log';

  /// Settings, from the CV tab.
  static const settings = '$cv/$settingsSegment';
  static const settingsSegment = 'settings';

  /// The form for a new gym, and for one gym and its walls.
  static const gymNew = '$settings/gyms/$newSegment';
  static String gym(String gymId) =>
      '$settings/gyms/${Uri.encodeComponent(gymId)}';
  static const gymNewSegment = 'gyms/$newSegment';
  static const gymSegment = 'gyms/:gymId';

  /// Debug builds only: every design token.
  static const tokenPreview = '/debug/tokens';
}
