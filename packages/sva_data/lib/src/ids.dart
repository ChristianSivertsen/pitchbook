import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Namespace for [seedId]. Never change it: seeded rows on every device
/// and on the server share their ids through it.
const _seedNamespace = '17ccc182-8b5c-4c3b-8014-e9a93a7aff44';

/// A new row id: a UUIDv7, which sorts by creation time (docs/schema.md).
String newId() => _uuid.v7();

/// The id of a seeded shared row, the same on every device and the server,
/// derived from a stable name such as `attribute_def:hold`.
String seedId(String name) => _uuid.v5(_seedNamespace, name);
