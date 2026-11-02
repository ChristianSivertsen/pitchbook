import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sva/src/app.dart';
import 'package:sva/src/data/device_database.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/icon_licenses.dart';
import 'package:sva_ui/sva_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerSvaFontLicenses();
  registerIconLicenses();
  final db = await openDeviceDatabase(userId: localUserId);
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const SvaApp(),
    ),
  );
}
