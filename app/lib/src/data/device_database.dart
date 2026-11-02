import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sva_data/sva_data.dart';

/// Opens the database on the phone, in the app's private support folder
/// (not the user's documents), and adds the built-in grades and details.
/// Debug builds also get the example data, so screens have something to
/// show while they are built.
Future<SvaDatabase> openDeviceDatabase({required String userId}) async {
  final folder = await getApplicationSupportDirectory();
  final db = SvaDatabase.onDevice(File('${folder.path}/sva.sqlite'));
  await GradeRepository(db).seed();
  await AttributeRepository(db).seed();
  if (kDebugMode) await seedExampleData(db, userId: userId);
  return db;
}
