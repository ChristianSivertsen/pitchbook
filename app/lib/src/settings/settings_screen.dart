import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/app_version.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/form_parts.dart';
import 'package:sva_core/sva_core.dart' show GradeSystem;
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// Personal preferences, from the CV tab: theme, language, grade systems,
/// who sees new sessions, and the app's version and licences. Every choice
/// is saved on the device at once and the app follows it straight away.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = context.svaText;
    final muted = text.caption.copyWith(color: context.svaColors.textMuted);
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final systems = ref.watch(gradeSystemsProvider).value ?? const [];
    final userId = ref.watch(currentUserIdProvider);

    /// Runs [save], and says so if it fails; the screen keeps showing what
    /// is saved.
    void change(Future<void> Function(SettingsRepository settings) save) {
      final messenger = ScaffoldMessenger.of(context);
      unawaited(
        // Inside a Future, so a value the repository refuses at once
        // (an ArgumentError) is caught like a failed write.
        Future(() => save(ref.read(settingsRepositoryProvider)))
            .catchError((Object _) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.settingsSaveFailed)),
              );
            }),
      );
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: SvaSpace.xl, bottom: SvaSpace.sm),
      child: Semantics(header: true, child: Text(title, style: text.headline)),
    );

    // Grade types in the order the systems come, each once.
    final byType = <String, List<GradeSystem>>{};
    for (final system in systems) {
      (byType[system.gradeType] ??= []).add(system);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SvaSpace.screen,
          0,
          SvaSpace.screen,
          SvaSpace.xxl,
        ),
        children: [
          ChipGroup(
            label: l10n.settingsTheme,
            options: [
              for (final theme in themes)
                (theme, l10n.settingsThemeOption(theme)),
            ],
            selected: {settings.theme},
            onChanged: (picked) {
              if (picked.isEmpty) return;
              change(
                (repository) => repository.setTheme(userId, picked.single),
              );
            },
          ),
          formGap,
          ChipGroup(
            label: l10n.settingsLanguage,
            options: [
              ('system', l10n.settingsLanguageSystem),
              ('nb', l10n.settingsLanguageNb),
              ('en', l10n.settingsLanguageEn),
            ],
            selected: {settings.language ?? 'system'},
            onChanged: (picked) {
              if (picked.isEmpty) return;
              final language = picked.single == 'system' ? null : picked.single;
              change((repository) => repository.setLanguage(userId, language));
            },
          ),
          formGap,
          ChipGroup(
            label: l10n.settingsVisibility,
            options: [
              for (final visibility in const ['private', 'friends', 'public'])
                (visibility, l10n.settingsVisibilityOption(visibility)),
            ],
            selected: {settings.defaultVisibility},
            onChanged: (picked) {
              if (picked.isEmpty) return;
              change(
                (repository) =>
                    repository.setDefaultVisibility(userId, picked.single),
              );
            },
          ),
          const SizedBox(height: SvaSpace.xs),
          Text(l10n.settingsVisibilityNote, style: muted),
          section(l10n.settingsGrades),
          Text(l10n.settingsGradesNote, style: muted),
          for (final MapEntry(key: type, value: options) in byType.entries) ...[
            formGap,
            ChipGroup(
              label: l10n.settingsGradeType(type),
              options: [
                for (final system in options)
                  (system.key, l10n.gradeSystemName(system.key)),
              ],
              selected: {?settings.gradeSystemFor(type)},
              onChanged: (picked) {
                if (picked.isEmpty) return;
                change(
                  (repository) =>
                      repository.setGradeSystem(userId, type, picked.single),
                );
              },
            ),
          ],
          section(l10n.settingsAbout),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsVersion, style: text.body),
            trailing: Text(appVersion, style: text.body),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsLicences, style: text.body),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Sva',
              applicationVersion: appVersion,
              applicationIcon: const Padding(
                padding: EdgeInsets.all(SvaSpace.md),
                child: SvaMark(size: 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
