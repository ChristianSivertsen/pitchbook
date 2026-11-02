/// Every path in the app, in one place. Share links and notifications open
/// these paths, so they are part of the app's public interface: change them
/// only with a redirect from the old path.
///
/// Planned paths that later tickets add under the same scheme:
/// - `/feed/session/:sessionId` for a session (share links, notifications)
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

  /// One route. Share links open it, so the id is checked by the screen.
  static String route(String routeId) =>
      '$history/route/${Uri.encodeComponent(routeId)}';
  static const routeSegment = 'route/:routeId';

  /// The log sheet, opened from inside the app with `push`. Opens over
  /// whichever tab is showing.
  static const log = '/log';

  /// The log sheet for links and notifications: opens over the feed.
  static const logLink = '$feed/$logLinkSegment';

  /// Path segment of [logLink] below [feed].
  static const logLinkSegment = 'log';

  /// Debug builds only: every design token.
  static const tokenPreview = '/debug/tokens';
}
