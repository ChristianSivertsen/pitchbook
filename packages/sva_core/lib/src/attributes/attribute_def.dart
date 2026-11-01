/// Where an attribute is recorded. Values are inherited downwards:
/// area → route → ascent (docs/schema.md, attribute_defs).
enum AttributeLevel { area, route, pitch, ascent, session }

/// How an attribute's value is shaped.
enum AttributeValueType {
  /// One key from [AttributeDef.valueKeys].
  single,

  /// Any number of keys from [AttributeDef.valueKeys].
  multi,

  /// A number, stored as text.
  number,

  /// `true` or `false`.
  bool,
}

/// The definition of one detail that can be logged, such as hold types or
/// ascent tags. Definitions are data, so a new detail needs no code: the
/// log form and the Explorer list whatever definitions exist.
///
/// Display text comes from translations, keyed by [key] and each value key.
final class AttributeDef {
  const new({
    required this.key,
    required this.level,
    required this.valueType,
    this.valueKeys = const [],
    this.sort = 0,
  });

  /// Stable key, for example `hold`.
  final String key;
  final AttributeLevel level;
  final AttributeValueType valueType;

  /// Allowed value keys for [AttributeValueType.single] and
  /// [AttributeValueType.multi], for example `hold.crimp`.
  final List<String> valueKeys;

  /// Order in forms and lists.
  final int sort;

  /// Whether [values] is a valid value for this attribute. An empty list
  /// means "not set" and is always valid.
  bool accepts(List<String> values) {
    if (values.isEmpty) return true;
    return switch (valueType) {
      AttributeValueType.single =>
        values.length == 1 && valueKeys.contains(values.single),
      AttributeValueType.multi =>
        values.toSet().length == values.length &&
            values.every(valueKeys.contains),
      AttributeValueType.number =>
        values.length == 1 && num.tryParse(values.single) != null,
      AttributeValueType.bool =>
        values.length == 1 && const {'true', 'false'}.contains(values.single),
    };
  }
}
