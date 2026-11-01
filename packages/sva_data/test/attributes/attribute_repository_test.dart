import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

void main() {
  late SvaDatabase db;
  late AttributeRepository repo;
  final now = DateTime.utc(2026, 11);

  setUp(() {
    db = SvaDatabase(NativeDatabase.memory());
    repo = AttributeRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<void> addArea(String id, {String? parentId, String? rock}) => db
      .into(db.areas)
      .insert(
        AreasCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          visibility: 'public',
          parentId: Value(parentId),
          type: parentId == null ? 'crag' : 'sector',
          name: id,
          countryCode: 'NO',
          rockType: Value(rock),
        ),
      );

  Future<void> addRoute(String id, String areaId, {String? angle}) => db
      .into(db.routes)
      .insert(
        RoutesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          visibility: 'public',
          areaId: areaId,
          kind: 'outdoor',
          discipline: 'sport',
          status: 'open',
          angle: Value(angle),
        ),
      );

  Future<void> addAscent(String id, String routeId, {String? feel}) => db
      .into(db.ascents)
      .insert(
        AscentsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          ownerId: 'me',
          visibility: 'friends',
          sessionId: 'session',
          routeId: routeId,
          ordinal: 1,
          ascentType: 'lead',
          style: 'redpoint',
          tries: 3,
          setting: 'outdoor',
          discipline: 'sport',
          feel: Value(feel),
        ),
      );

  test('M1-2: seeded attribute definitions load', () async {
    await repo.seed();
    await repo.seed(); // seeding again updates instead of duplicating

    final loaded = await repo.definitions();
    expect(loaded, hasLength(attributeSeed.length));
    for (final def in attributeSeed) {
      final match = loaded.singleWhere((d) => d.key == def.key);
      expect(match.level, def.level, reason: def.key);
      expect(match.valueType, def.valueType, reason: def.key);
      expect(match.valueKeys, def.valueKeys, reason: def.key);
    }
    final ids = await db.select(db.attributeDefs).get();
    expect(
      ids.map((row) => row.id),
      containsAll(attributeSeed.map((d) => seedId('attribute_def:${d.key}'))),
      reason: 'seeded ids are the same on every device',
    );
    expect(
      (await repo.definitions(level: AttributeLevel.ascent)).map((d) => d.key),
      ['feel', 'tag'],
    );
  });

  test(
    'M1-2: an ascent resolves values from its crag, route and itself',
    () async {
      await repo.seed();
      await addArea('crag', rock: 'rock.granite');
      await addArea('sector', parentId: 'crag');
      await addRoute('route', 'sector', angle: 'angle.overhang');
      await repo.setRouteAttribute('route', 'hold', ['hold.pinch', 'hold.jug']);
      await addAscent('ascent', 'route', feel: 'feel.hard');
      await repo.setAscentAttribute(
        'ascent',
        'tag',
        ['tag.pumpy'],
        ownerId: 'me',
        visibility: 'friends',
      );

      expect(await repo.resolvedForAscent('ascent'), {
        'rock_type': ['rock.granite'],
        'discipline': ['sport'],
        'angle': ['angle.overhang'],
        'hold': ['hold.jug', 'hold.pinch'],
        'feel': ['feel.hard'],
        'tag': ['tag.pumpy'],
      });
    },
  );

  test('M1-2: adding a definition in seed data needs no code change', () async {
    const surface = AttributeDef(
      key: 'surface',
      level: AttributeLevel.route,
      valueType: AttributeValueType.multi,
      valueKeys: ['surface.polished', 'surface.lichen'],
      sort: 99,
    );
    await repo.seed([...attributeSeed, surface]);
    await addArea('crag', rock: 'rock.limestone');
    await addRoute('route', 'crag');
    await addAscent('ascent', 'route');

    final routeDefs = await repo.definitions(level: AttributeLevel.route);
    expect(routeDefs.last.key, 'surface');

    await repo.setRouteAttribute('route', 'surface', ['surface.lichen']);
    expect((await repo.resolvedForAscent('ascent'))['surface'], [
      'surface.lichen',
    ]);

    // The same checks guard new attributes as existing ones.
    expect(
      () => repo.setRouteAttribute('route', 'surface', ['surface.mud']),
      throwsArgumentError,
    );
    expect(
      () => repo.setRouteAttribute('route', 'angle', ['angle.slab']),
      throwsArgumentError,
      reason: 'typed columns are written with the route',
    );
    expect(
      () => repo.setRouteAttribute('route', 'unknown', ['x']),
      throwsArgumentError,
    );
  });
}
