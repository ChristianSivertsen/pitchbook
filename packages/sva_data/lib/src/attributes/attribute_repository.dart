import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/seed/attribute_seed.dart';

/// Reads and writes attribute definitions and values. Values live in a
/// typed column when [typedAttributeColumns] lists the key, otherwise in
/// the level's attribute table, so a new definition needs no code here.
class AttributeRepository {
  new(this._db, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final SvaDatabase _db;
  final DateTime Function() _clock;

  /// Levels with an attribute table for non-typed values.
  static const Set<AttributeLevel> _stored = {
    AttributeLevel.route,
    AttributeLevel.ascent,
  };

  static const Map<AttributeLevel, String> _tables = {
    AttributeLevel.area: 'areas',
    AttributeLevel.route: 'routes',
    AttributeLevel.ascent: 'ascents',
    AttributeLevel.session: 'sessions',
  };

  /// Bootstraps the shared definitions on the device until the server
  /// delivers them through sync (M11-4), after which the server owns them.
  /// Ids come from the key, so every device and the server agree on them.
  /// A definition the server deleted stays deleted.
  ///
  /// Throws [ArgumentError] for a non-typed definition at a level that has
  /// no attribute table yet (area, pitch, session): it could not be stored.
  Future<void> seed([Iterable<AttributeDef> defs = attributeSeed]) async {
    for (final def in defs) {
      final typed = typedAttributeColumns[def.level]?.containsKey(def.key);
      if (!_stored.contains(def.level) && !(typed ?? false)) {
        throw ArgumentError.value(def.key, 'defs', 'cannot be stored yet');
      }
    }
    final now = _clock();
    await _db.batch((batch) {
      for (final def in defs) {
        batch.insert(
          _db.attributeDefs,
          AttributeDefsCompanion.insert(
            id: seedId('attribute_def:${def.key}'),
            createdAt: now,
            updatedAt: now,
            key: def.key,
            level: def.level.name,
            valueType: def.valueType.name,
            valueKeys: Value(jsonEncode(def.valueKeys)),
            sort: def.sort,
          ),
          onConflict: DoUpdate(
            (_) => AttributeDefsCompanion(
              updatedAt: Value(now),
              level: Value(def.level.name),
              valueType: Value(def.valueType.name),
              valueKeys: Value(jsonEncode(def.valueKeys)),
              sort: Value(def.sort),
            ),
          ),
        );
      }
    });
  }

  /// Every definition in use, optionally for one level, in display order.
  Future<List<AttributeDef>> definitions({AttributeLevel? level}) async {
    final query = _db.select(_db.attributeDefs)
      ..where((d) => d.deletedAt.isNull())
      ..orderBy([
        (d) => OrderingTerm(expression: d.sort),
        (d) => OrderingTerm(expression: d.key),
      ]);
    if (level != null) query.where((d) => d.level.equals(level.name));
    final rows = await query.get();
    return [for (final row in rows) ?_toDef(row)];
  }

  /// Sets the values of a non-typed attribute on a private route that
  /// [userId] created, replacing what was there. Public routes are shared
  /// and change only through moderated requests (docs/schema.md).
  ///
  /// Throws [ArgumentError] when the definition is missing, the key is a
  /// typed column or the values are not allowed, and [StateError] when the
  /// route does not exist, is public or belongs to someone else.
  Future<void> setRouteAttribute(
    String routeId,
    String key,
    List<String> values, {
    required String userId,
  }) async {
    final def = await _definition(key, AttributeLevel.route);
    _checkWritable(def, key, values);
    final now = _clock();
    await _db.transaction(() async {
      final route = await (_db.select(
        _db.routes,
      )..where((r) => r.id.equals(routeId))).getSingleOrNull();
      if (route == null ||
          route.deletedAt != null ||
          route.visibility != 'private' ||
          route.createdBy != userId) {
        throw StateError('Route $routeId is not a private route of $userId');
      }
      final existing =
          await (_db.select(_db.routeAttributes)..where(
                (a) => a.routeId.equals(routeId) & a.attributeKey.equals(key),
              ))
              .get();
      final plan = _plan([
        for (final row in existing) (row.id, row.value, row.deletedAt),
      ], values);
      await _db.batch((batch) {
        for (final id in plan.delete) {
          batch.update(
            _db.routeAttributes,
            RouteAttributesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
            where: (a) => a.id.equals(id),
          );
        }
        for (final id in plan.revive) {
          batch.update(
            _db.routeAttributes,
            RouteAttributesCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
            where: (a) => a.id.equals(id),
          );
        }
        for (final value in plan.insert) {
          batch.insert(
            _db.routeAttributes,
            RouteAttributesCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              createdBy: Value(userId),
              routeId: routeId,
              attributeKey: key,
              value: value,
            ),
          );
        }
      });
    });
  }

  /// Sets the values of a non-typed attribute on one of [userId]'s ascents,
  /// replacing what was there. New rows copy the ascent's owner and
  /// visibility. Throws like [setRouteAttribute].
  Future<void> setAscentAttribute(
    String ascentId,
    String key,
    List<String> values, {
    required String userId,
  }) async {
    final def = await _definition(key, AttributeLevel.ascent);
    _checkWritable(def, key, values);
    final now = _clock();
    await _db.transaction(() async {
      final ascent = await (_db.select(
        _db.ascents,
      )..where((a) => a.id.equals(ascentId))).getSingleOrNull();
      if (ascent == null ||
          ascent.deletedAt != null ||
          ascent.ownerId != userId) {
        throw StateError('Ascent $ascentId is not an ascent of $userId');
      }
      final existing =
          await (_db.select(_db.ascentAttributes)..where(
                (a) => a.ascentId.equals(ascentId) & a.attributeKey.equals(key),
              ))
              .get();
      final plan = _plan([
        for (final row in existing) (row.id, row.value, row.deletedAt),
      ], values);
      await _db.batch((batch) {
        for (final id in plan.delete) {
          batch.update(
            _db.ascentAttributes,
            AscentAttributesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
            where: (a) => a.id.equals(id),
          );
        }
        for (final id in plan.revive) {
          batch.update(
            _db.ascentAttributes,
            AscentAttributesCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
              visibility: Value(ascent.visibility),
            ),
            where: (a) => a.id.equals(id),
          );
        }
        for (final value in plan.insert) {
          batch.insert(
            _db.ascentAttributes,
            AscentAttributesCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              ownerId: ascent.ownerId,
              visibility: ascent.visibility,
              ascentId: ascentId,
              attributeKey: key,
              value: value,
            ),
          );
        }
      });
    });
  }

  /// The values recorded on one row, typed columns and attribute rows
  /// together. Deleted attribute rows are left out.
  Future<AttributeValues> valuesAt(AttributeLevel level, String id) async {
    final values = <String, List<String>>{};
    final table = _tables[level];
    final columns = typedAttributeColumns[level] ?? const {};
    if (table != null && columns.isNotEmpty) {
      // Table and column names come from constants, never from input.
      final row = await _db
          .customSelect(
            'SELECT ${columns.values.join(', ')} FROM $table WHERE id = ?',
            variables: [Variable.withString(id)],
          )
          .getSingleOrNull();
      if (row != null) {
        for (final MapEntry(:key, value: column) in columns.entries) {
          final value = row.data[column];
          if (value != null) values[key] = ['$value'];
        }
      }
    }
    final rows = switch (level) {
      AttributeLevel.route =>
        (await (_db.select(_db.routeAttributes)
                  ..where((a) => a.routeId.equals(id) & a.deletedAt.isNull())
                  ..orderBy([(a) => OrderingTerm(expression: a.value)]))
                .get())
            .map((a) => (a.attributeKey, a.value)),
      AttributeLevel.ascent =>
        (await (_db.select(_db.ascentAttributes)
                  ..where((a) => a.ascentId.equals(id) & a.deletedAt.isNull())
                  ..orderBy([(a) => OrderingTerm(expression: a.value)]))
                .get())
            .map((a) => (a.attributeKey, a.value)),
      _ => const <(String, String)>[],
    };
    for (final (key, value) in rows) {
      (values[key] ??= []).add(value);
    }
    return values;
  }

  /// What applies to a route: its own values, then every area above it,
  /// nearest first (see [resolveAttributes]). Rock type comes from the
  /// crag this way.
  Future<AttributeValues> resolvedForRoute(String routeId) async {
    final route = await (_db.select(
      _db.routes,
    )..where((r) => r.id.equals(routeId))).getSingle();
    return resolveAttributes([
      ...await _areaLayers(route.areaId),
      await valuesAt(AttributeLevel.route, route.id),
    ]);
  }

  /// What applies to an ascent: its own values, then its route's, then
  /// every area above the route, nearest first (see [resolveAttributes]).
  Future<AttributeValues> resolvedForAscent(String ascentId) async {
    final ascent = await (_db.select(
      _db.ascents,
    )..where((a) => a.id.equals(ascentId))).getSingle();
    final route = await (_db.select(
      _db.routes,
    )..where((r) => r.id.equals(ascent.routeId))).getSingle();
    return resolveAttributes([
      ...await _areaLayers(route.areaId),
      await valuesAt(AttributeLevel.route, route.id),
      await valuesAt(AttributeLevel.ascent, ascentId),
    ]);
  }

  /// The values of [areaId] and every area above it, top-most first.
  Future<List<AttributeValues>> _areaLayers(String? areaId) async {
    final layers = <AttributeValues>[];
    final seen = <String>{};
    var id = areaId;
    while (id != null && seen.add(id)) {
      layers.insert(0, await valuesAt(AttributeLevel.area, id));
      final current = id;
      final area = await (_db.select(
        _db.areas,
      )..where((a) => a.id.equals(current))).getSingleOrNull();
      id = area?.parentId;
    }
    return layers;
  }

  /// What to change so the live rows hold exactly [wanted]: rows are
  /// soft-deleted, not removed, and a value that comes back revives its
  /// old row, so ids stay stable for sync.
  static ({List<String> delete, List<String> revive, List<String> insert})
  _plan(List<(String, String, DateTime?)> existing, List<String> wanted) {
    final delete = <String>[];
    final revive = <String>[];
    final insert = <String>[];
    final remaining = wanted.toSet();
    for (final (id, value, deletedAt) in existing) {
      final want = remaining.remove(value);
      if (want && deletedAt != null) revive.add(id);
      if (!want && deletedAt == null) delete.add(id);
    }
    insert.addAll(remaining);
    return (delete: delete, revive: revive, insert: insert);
  }

  Future<AttributeDef> _definition(String key, AttributeLevel level) async {
    final defs = await definitions(level: level);
    final def = defs.where((d) => d.key == key).firstOrNull;
    if (def == null) {
      throw ArgumentError.value(key, 'key', 'no ${level.name} attribute');
    }
    return def;
  }

  void _checkWritable(AttributeDef def, String key, List<String> values) {
    if (typedAttributeColumns[def.level]?.containsKey(key) ?? false) {
      throw ArgumentError.value(key, 'key', 'is stored in a typed column');
    }
    if (!def.accepts(values)) {
      throw ArgumentError.value(values, 'values', 'not allowed for $key');
    }
  }

  AttributeDef? _toDef(AttributeDefRow row) {
    final level = AttributeLevel.values.asNameMap()[row.level];
    final type = AttributeValueType.values.asNameMap()[row.valueType];
    // Definitions from a newer app version, or malformed rows from sync,
    // are skipped rather than breaking every form.
    if (level == null || type == null) return null;
    final List<String> valueKeys;
    try {
      valueKeys = row.valueKeys == null
          ? const []
          : List<String>.from(jsonDecode(row.valueKeys!) as List<Object?>);
    } on Object {
      return null;
    }
    return AttributeDef(
      key: row.key,
      level: level,
      valueType: type,
      valueKeys: valueKeys,
      sort: row.sort,
    );
  }
}
