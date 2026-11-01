import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:sva_data/sva_data.dart';
import 'package:test/test.dart';

/// Every value [stream] emits on one subscription while [act] runs.
Future<List<T>> emissions<T>(
  Stream<T> stream,
  Future<void> Function() act,
) async {
  final seen = <T>[];
  final subscription = stream.listen(seen.add);
  await pumpEventQueue();
  await act();
  await pumpEventQueue();
  await subscription.cancel();
  return seen;
}

/// Create, read, update, soft delete and watch one row of [repo].
Future<void> lifecycle<T extends Table, R>(
  SvaDatabase db,
  Repository<T, R> repo,
  Future<String> Function() create,
  Insertable<R> changes,
  Object? Function(R row) changed,
  Object? expected,
) async {
  final name = repo.table.actualTableName;
  final id = await create();
  Future<Object?> stamp() async =>
      (await db
              .customSelect(
                'SELECT updated_at FROM $name WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .data['updated_at'];

  final seen = await emissions(repo.watch(id), () async {
    final before = await stamp();
    await repo.update(id, changes, userId: 'me');
    expect(changed((await repo.get(id)) as R), expected, reason: name);
    expect(await stamp(), isNot(before), reason: '$name updated_at moves');
    await repo.softDelete(id, userId: 'me');
  });
  expect(await repo.get(id), isNull, reason: name);
  expect(seen.whereType<R>(), isNotEmpty, reason: name);
  expect(seen.last, isNull, reason: '$name watchers see the delete');
  final kept = await db
      .customSelect(
        'SELECT deleted_at FROM $name WHERE id = ?',
        variables: [Variable.withString(id)],
      )
      .getSingle();
  expect(kept.data['deleted_at'], isNotNull, reason: '$name rows are kept');
}
