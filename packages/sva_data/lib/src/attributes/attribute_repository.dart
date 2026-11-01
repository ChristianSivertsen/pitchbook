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

  static const Map<AttributeLevel, String> _tables = {
    AttributeLevel.area: 'areas',
    AttributeLevel.route: 'routes',
    AttributeLevel.ascent: 'ascents',
    AttributeLevel.session: 'sessions',
  };

  /// Adds or updates the shared definitions. Ids come from the key, so every
  /// device and the server agree on them.
  Future<void> seed([Iterable<AttributeDef> defs = attributeSeed]) async {
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
              deletedAt: const Value(null),
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
      ..orderBy([(d) => OrderingTerm(expression: d.sort)]);
    if (level != null) query.where((d) => d.level.equals(level.name));
    final rows = await query.get();
    return [for (final row in rows) ?_toDef(row)];
  }

  /// Sets the values of a non-typed attribute on a route, replacing what
  /// was there. Throws [ArgumentError] when the definition is missing, the
  /// key is a typed column or the values are not allowed.
  Future<void> setRouteAttribute(
    String routeId,
    String key,
    List<String> values, {
    String? createdBy,
  }) async {
    final def = await _definition(key, AttributeLevel.route);
    _checkWritable(def, key, values);
    final now = _clock();
    await _db.transaction(() async {
      await (_db.delete(_db.routeAttributes)..where(
            (a) => a.routeId.equals(routeId) & a.attributeKey.equals(key),
          ))
          .go();
      for (final value in values) {
        await _db
            .into(_db.routeAttributes)
            .insert(
              RouteAttributesCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                createdBy: Value(createdBy),
                routeId: routeId,
                attributeKey: key,
                value: value,
              ),
            );
      }
    });
  }

  /// Sets the values of a non-typed attribute on one of the owner's
  /// ascents, replacing what was there.
  Future<void> setAscentAttribute(
    String ascentId,
    String key,
    List<String> values, {
    required String ownerId,
    required String visibility,
  }) async {
    final def = await _definition(key, AttributeLevel.ascent);
    _checkWritable(def, key, values);
    final now = _clock();
    await _db.transaction(() async {
      await (_db.delete(_db.ascentAttributes)..where(
            (a) => a.ascentId.equals(ascentId) & a.attributeKey.equals(key),
          ))
          .go();
      for (final value in values) {
        await _db
            .into(_db.ascentAttributes)
            .insert(
              AscentAttributesCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                ownerId: ownerId,
                visibility: visibility,
                ascentId: ascentId,
                attributeKey: key,
                value: value,
              ),
            );
      }
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

  /// What applies to an ascent: its own values, then its route's, then
  /// every area above the route, nearest first (see [resolveAttributes]).
  Future<AttributeValues> resolvedForAscent(String ascentId) async {
    final ascent = await (_db.select(
      _db.ascents,
    )..where((a) => a.id.equals(ascentId))).getSingle();
    final route = await (_db.select(
      _db.routes,
    )..where((r) => r.id.equals(ascent.routeId))).getSingle();
    final areaLayers = <AttributeValues>[];
    final seen = <String>{};
    String? areaId = route.areaId;
    while (areaId != null && seen.add(areaId)) {
      areaLayers.insert(0, await valuesAt(AttributeLevel.area, areaId));
      final area = await (_db.select(
        _db.areas,
      )..where((a) => a.id.equals(areaId!))).getSingleOrNull();
      areaId = area?.parentId;
    }
    return resolveAttributes([
      ...areaLayers,
      await valuesAt(AttributeLevel.route, route.id),
      await valuesAt(AttributeLevel.ascent, ascentId),
    ]);
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
    // Definitions from a newer app version are skipped, not fatal.
    if (level == null || type == null) return null;
    return AttributeDef(
      key: row.key,
      level: level,
      valueType: type,
      valueKeys: switch (row.valueKeys) {
        final String json => (jsonDecode(json) as List<Object?>).cast<String>(),
        null => const [],
      },
      sort: row.sort,
    );
  }
}
