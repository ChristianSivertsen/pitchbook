import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sva_data/sva_data.dart';

/// The local database. `main` opens it on the device once the first data
/// screen lands (M2-3); tests override it with [SvaDatabase.inMemory].
final databaseProvider = Provider<SvaDatabase>(
  (ref) => throw UnimplementedError('Override databaseProvider'),
);

/// The user whose rows screens read and write. Before sign-in this is a
/// local id, replaced on first sign-in (docs/schema.md, profiles).
final currentUserIdProvider = Provider<String>((ref) => 'local');

final Provider<AreaRepository> areaRepositoryProvider = Provider(
  (ref) => AreaRepository(ref.watch(databaseProvider)),
);
final Provider<RouteRepository> routeRepositoryProvider = Provider(
  (ref) => RouteRepository(ref.watch(databaseProvider)),
);
final Provider<GymWallRepository> gymWallRepositoryProvider = Provider(
  (ref) => GymWallRepository(ref.watch(databaseProvider)),
);
final Provider<GymColourGradeRepository> gymColourGradeRepositoryProvider =
    Provider((ref) => GymColourGradeRepository(ref.watch(databaseProvider)));
final Provider<SessionRepository> sessionRepositoryProvider = Provider(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);
final Provider<AscentRepository> ascentRepositoryProvider = Provider(
  (ref) => AscentRepository(ref.watch(databaseProvider)),
);

/// The user's sessions, newest first, live.
final StreamProvider<List<Session>> mySessionsProvider = StreamProvider(
  (ref) => ref
      .watch(sessionRepositoryProvider)
      .watchMine(userId: ref.watch(currentUserIdProvider)),
);

/// The climbs in one session, in order, live.
final StreamProviderFamily<List<Ascent>, String> sessionAscentsProvider =
    StreamProvider.autoDispose.family(
      (ref, sessionId) =>
          ref.watch(ascentRepositoryProvider).watchInSession(sessionId),
    );

/// The places under one place (the top level for `null`), live.
final StreamProviderFamily<List<Area>, String?> areaChildrenProvider =
    StreamProvider.autoDispose.family(
      (ref, parentId) => ref
          .watch(areaRepositoryProvider)
          .watchChildren(parentId, userId: ref.watch(currentUserIdProvider)),
    );

/// The routes in one place, live.
final StreamProviderFamily<List<Route>, String> routesInAreaProvider =
    StreamProvider.autoDispose.family(
      (ref, areaId) => ref
          .watch(routeRepositoryProvider)
          .watchInArea(areaId, userId: ref.watch(currentUserIdProvider)),
    );
