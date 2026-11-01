import 'package:drift/drift.dart';
import 'package:sva_data/src/database/tables/personal.dart';
import 'package:sva_data/src/database/tables/places.dart';
import 'package:sva_data/src/database/tables/routes.dart';
import 'package:sva_data/src/database/tables/sessions.dart';
import 'package:sva_data/src/database/tables/users.dart';

part 'sva_database.g.dart';

/// The app's local database. Tables follow docs/schema.md and the
/// PowerSync rules in `tables/conventions.dart`.
///
/// Changing a table: bump [schemaVersion], add a step to [migration], then
/// run `dart run drift_dev make-migrations` in `packages/sva_data`. It saves
/// the new schema in `drift_schemas/` and the test helpers in
/// `test/generated_migrations/sva/generated/`. Delete the
/// `migration_test.dart` template it writes: `test/database/schema_test.dart`
/// already migrates every saved version. Never edit a step that has been
/// merged.
@DriftDatabase(
  tables: [
    Profiles,
    Areas,
    GymProfiles,
    GymWalls,
    GymColourGrades,
    Routes,
    Pitches,
    GradeSystems,
    Grades,
    RouteGrades,
    AttributeDefs,
    RouteAttributes,
    Topos,
    Trips,
    TripMembers,
    ClimbGroups,
    Sessions,
    WeatherSnapshots,
    SessionMembers,
    Ascents,
    AscentBeta,
    AscentPitches,
    AscentAttributes,
    AscentGear,
    Media,
    GearModels,
    GearPieces,
    GearEvents,
    Shoes,
    ShoeResoles,
    TicklistItems,
    Projects,
    Goals,
    BenchmarkDefs,
    BenchmarkResults,
  ],
)
class SvaDatabase extends _$SvaDatabase {
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
