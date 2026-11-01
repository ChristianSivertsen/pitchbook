/// Every path in the app, in one place. Share links and notifications open
/// these paths, so they are part of the app's public interface: change them
/// only with a redirect from the old path.
///
/// Planned paths that later tickets add under the same scheme:
/// - `/feed/session/:sessionId` for a session (share links, notifications)
/// - `/history/route/:routeId` for a route
/// - `/cv/rack/:pieceId`, `/cv/shoes/:shoeId` for gear details
/// - `/training/:benchmarkId` for a benchmark
/// - `/people/:userId` for a climber's profile
abstract final class Routes {
  static const feed = '/feed';
  static const history = '/history';
  static const cv = '/cv';
  static const training = '/training';

  /// The log sheet. Opens over whichever tab is showing.
  static const log = '/log';

  /// Debug builds only: every design token.
  static const tokenPreview = '/debug/tokens';
}
