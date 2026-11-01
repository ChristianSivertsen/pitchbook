import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/app.dart';

/// Message keys in an ARB file, without metadata entries.
Set<String> messageKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('M0-5: every English text has a Norwegian translation', () {
    final english = messageKeys('lib/l10n/app_en.arb');
    final norwegian = messageKeys('lib/l10n/app_nb.arb');
    expect(english.difference(norwegian), isEmpty, reason: 'missing in nb');
    expect(norwegian.difference(english), isEmpty, reason: 'unknown in nb');
  });

  test('M0-5: the app supports Norwegian Bokmål and English', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(const [Locale('en'), Locale('nb')]),
    );
  });

  test('M0-5: Norwegian phones get Bokmål, others fall back to English', () {
    const supported = AppLocalizations.supportedLocales;
    for (final code in ['nb', 'nn', 'no']) {
      expect(resolveLocale(Locale(code, 'NO'), supported), const Locale('nb'));
    }
    expect(
      resolveLocale(const Locale('en', 'GB'), supported).languageCode,
      'en',
    );
    expect(resolveLocale(const Locale('de'), supported), const Locale('en'));
    expect(resolveLocale(null, supported), const Locale('en'));
  });

  testWidgets('M0-5: the app shows Norwegian on a Norwegian phone', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nb', 'NO')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: SvaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Historikk'), findsOneWidget);
    expect(find.text('Øktene dine dukker opp her'), findsOneWidget);
    expect(find.bySemanticsLabel('Logg en økt'), findsWidgets);
  });
}
