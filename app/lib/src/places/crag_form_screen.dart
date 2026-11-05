import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/form_parts.dart';
import 'package:sva/src/places/location_picker.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// The form for a new crag. Closes with the new crag's id.
class CragFormScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CragFormScreen> createState() => _CragFormScreenState();
}

class _CragFormScreenState extends ConsumerState<CragFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController(text: 'NO');
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  String? _rock;
  var _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _country, _lat, _lon]) {
      c.dispose();
    }
    super.dispose();
  }

  LatLon? get _location => LocationFields.locationOf(_lat, _lon);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(routeEditorProvider)
          .addCrag(
            NewCrag(
              name: _name.text,
              countryCode: _country.text.trim().toUpperCase(),
              rockType: _rock,
              location: _location,
            ),
            userId: ref.read(currentUserIdProvider),
          );
      if (mounted) context.pop(id);
    } on Object {
      // The form checks every field first, so this is a database failure
      // or a value the repository refused.
      messenger.showSnackBar(SnackBar(content: Text(l10n.formSaveFailed)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rocks = attributeSeed
        .firstWhere((d) => d.key == 'rock_type')
        .valueKeys;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cragFormTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(SvaSpace.screen),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.formName),
              textCapitalization: TextCapitalization.words,
              maxLength: maxNameLength,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.cragFormNameMissing : null,
            ),
            formGap,
            TextFormField(
              controller: _country,
              decoration: InputDecoration(labelText: l10n.cragFormCountry),
              textCapitalization: TextCapitalization.characters,
              maxLength: 2,
              validator: (v) =>
                  RegExp(r'^[A-Za-z]{2}$').hasMatch((v ?? '').trim())
                  ? null
                  : l10n.cragFormCountryInvalid,
            ),
            formGap,
            ChipGroup(
              label: l10n.cragFormRock,
              options: [
                for (final rock in rocks)
                  (rock, l10n.attributeValue(rock.replaceAll('.', '_'))),
              ],
              selected: {?_rock},
              onChanged: (v) => setState(() => _rock = v.firstOrNull),
            ),
            formGap,
            LocationFields(
              lat: _lat,
              lon: _lon,
              mapLabel: l10n.cragFormMap,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SvaSpace.screen),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.cragFormSave),
          ),
        ),
      ),
    );
  }
}
