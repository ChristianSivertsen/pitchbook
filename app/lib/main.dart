import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sva/src/app.dart';
import 'package:sva/src/icon_licenses.dart';
import 'package:sva_ui/sva_ui.dart';

void main() {
  registerSvaFontLicenses();
  registerIconLicenses();
  runApp(const ProviderScope(child: SvaApp()));
}
