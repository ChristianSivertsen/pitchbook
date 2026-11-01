/// Attribute values recorded at one level: attribute key → value keys.
/// A missing key or an empty list means "not set here".
typedef AttributeValues = Map<String, List<String>>;

/// Combines the values recorded at each level into what applies to the
/// most specific one.
///
/// [layers] go from the most general to the most specific, for example a
/// crag, its sector, the route and then the ascent. For each attribute the
/// most specific level that sets it wins; values are never merged across
/// levels, so a route that lists its own holds replaces the crag's.
AttributeValues resolveAttributes(Iterable<AttributeValues> layers) {
  final resolved = <String, List<String>>{};
  for (final layer in layers) {
    for (final MapEntry(:key, :value) in layer.entries) {
      if (value.isNotEmpty) resolved[key] = List.unmodifiable(value);
    }
  }
  return Map.unmodifiable(resolved);
}
