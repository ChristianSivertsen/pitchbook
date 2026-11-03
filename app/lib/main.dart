import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sva/src/app.dart';
import 'package:sva/src/data/device_database.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/icon_licenses.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerSvaFontLicenses();
  registerIconLicenses();
  final db = await openDeviceDatabase(userId: localUserId);
  final weather = WeatherFiller(db, OpenMeteo());
  // Sessions saved without signal get their weather on the next try.
  unawaited(weather.fillMissing(userId: localUserId));
  Timer.periodic(
    _weatherRetry,
    (_) => unawaited(weather.fillMissing(userId: localUserId)),
  );
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        weatherFillerProvider.overrideWithValue(weather),
      ],
      child: const SvaApp(),
    ),
  );
}

/// How often to look for sessions still missing their weather.
const _weatherRetry = Duration(minutes: 15);
