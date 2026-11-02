import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/data/providers.dart';
import 'package:sva/src/places/form_parts.dart';
import 'package:sva/src/routes.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/sva_data.dart';
import 'package:sva_ui/sva_ui.dart';

/// Rope lengths offered as chips, in metres.
const _ropeLengths = [50, 60, 70, 80];

/// The form for a new outdoor route, with every detail as tappable chips
/// and a pitch table for multipitch routes. Opens the new route on save.
class RouteFormScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends ConsumerState<RouteFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _length = TextEditingController();
  final _pitchCount = TextEditingController(text: '1');
  final _firstAscent = TextEditingController();
  final _pitchLengths = <TextEditingController>[];
  final _pitchGrades = <String?>[];
  String? _areaId;
  var _discipline = 'sport';
  String? _grade;
  var _details = <String, Set<String>>{};
  int? _rope;
  var _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _length,
      _pitchCount,
      _firstAscent,
      ..._pitchLengths,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Grade systems used until the settings screen lets the user choose
  /// (M2-8): Norwegian for routes, Font for boulders.
  String get _systemKey => _discipline == 'boulder' ? 'font' : 'nor';

  int get _pitches => int.tryParse(_pitchCount.text.trim()) ?? 1;

  void _setPitches(String text) {
    final count = (int.tryParse(text.trim()) ?? 1).clamp(1, maxPitches);
    setState(() {
      while (_pitchLengths.length < count) {
        _pitchLengths.add(TextEditingController());
        _pitchGrades.add(null);
      }
      while (_pitchLengths.length > count) {
        _pitchLengths.removeLast().dispose();
        _pitchGrades.removeLast();
      }
    });
  }

  String? _checkPitches(String? text, AppLocalizations l10n) {
    final value = (text ?? '').trim();
    if (value.isEmpty) return null;
    final number = int.tryParse(value);
    return number == null || number < 1 || number > maxPitches
        ? l10n.formNumberInvalid(maxPitches)
        : null;
  }

  String? _checkLength(String? text, AppLocalizations l10n) {
    final value = (text ?? '').trim();
    if (value.isEmpty) return null;
    final metres = parseDecimal(value);
    return metres == null || metres <= 0 || metres > maxRouteLengthM
        ? l10n.formLengthInvalid(maxRouteLengthM.toInt())
        : null;
  }

  String _gradeId(String label) => seedId('grade:$_systemKey:$label');

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final multipitch = _pitches > 1;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(routeEditorProvider)
          .addRoute(
            NewRoute(
              areaId: _areaId!,
              name: _name.text,
              discipline: _discipline,
              gradeId: _grade == null ? null : _gradeId(_grade!),
              lengthM: parseDecimal(_length.text),
              pitches: [
                if (multipitch)
                  for (final (i, length) in _pitchLengths.indexed)
                    NewPitch(
                      gradeId: _pitchGrades[i] == null
                          ? null
                          : _gradeId(_pitchGrades[i]!),
                      lengthM: parseDecimal(length.text),
                    ),
              ],
              angle: _details['angle']?.firstOrNull,
              features: [...?_details['feature']],
              holds: [...?_details['hold']],
              protection: _details['protection']?.firstOrNull,
              descent: _details['descent']?.firstOrNull,
              ropeLengthM: _rope,
              firstAscent: _firstAscent.text,
            ),
            userId: ref.read(currentUserIdProvider),
          );
      if (mounted) context.pushReplacement(Routes.route(id));
    } on Object {
      // The form checks every field first, so this is a database failure
      // or a value the repository refused.
      messenger.showSnackBar(SnackBar(content: Text(l10n.formSaveFailed)));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _newCrag() async {
    final id = await context.push<String>(Routes.cragNew);
    if (id != null && mounted) setState(() => _areaId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final places = ref.watch(routePlacesProvider).value ?? const <Area>[];
    final system = ref
        .watch(gradeSystemsProvider)
        .value
        ?.where((s) => s.key == _systemKey)
        .firstOrNull;
    final crag = places.where((p) => p.id == _areaId).firstOrNull;

    List<(String, String)> optionsFor(String key) => [
      for (final value
          in attributeSeed.firstWhere((d) => d.key == key).valueKeys)
        (value, l10n.attributeValue(value.replaceAll('.', '_'))),
    ];
    Widget details(String key, String label, {bool multi = false}) => Padding(
      padding: const EdgeInsets.only(top: SvaSpace.lg),
      child: ChipGroup(
        label: label,
        options: optionsFor(key),
        multi: multi,
        selected: _details[key] ?? const {},
        onChanged: (v) => setState(() => _details = {..._details, key: v}),
      ),
    );
    Widget gradeField({
      required String? value,
      required ValueChanged<String?> onChanged,
      String? label,
    }) => DropdownButtonFormField<String?>(
      // A new key resets the field when the grade system changes.
      key: ValueKey('$label $_systemKey'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label ?? l10n.routeFormGrade(system?.name ?? ''),
      ),
      items: [
        DropdownMenuItem(child: Text(l10n.routeFormNoGrade)),
        for (final grade in system?.grades ?? const <Grade>[])
          DropdownMenuItem(value: grade.label, child: Text(grade.label)),
      ],
      onChanged: onChanged,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeFormTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(SvaSpace.screen),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.formName),
              textCapitalization: TextCapitalization.sentences,
              maxLength: maxNameLength,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.routeFormNameMissing : null,
            ),
            formGap,
            DropdownButtonFormField<String>(
              key: ValueKey(_areaId),
              initialValue: _areaId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.routeFormCrag),
              items: [
                for (final place in places)
                  DropdownMenuItem(value: place.id, child: Text(place.name)),
              ],
              onChanged: (id) => setState(() => _areaId = id),
              validator: (id) => id == null ? l10n.routeFormCragMissing : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _newCrag, child: Text(l10n.cragAdd)),
            ),
            if (crag?.rockType case final rock?)
              Text(
                l10n.routeFormRockFromCrag(
                  l10n.attributeValue(rock.replaceAll('.', '_')),
                ),
                style: context.svaText.caption.copyWith(
                  color: colors.textMuted,
                ),
              ),
            formGap,
            ChipGroup(
              label: l10n.routeFormDiscipline,
              options: [
                for (final value
                    in attributeSeed
                        .firstWhere((d) => d.key == 'discipline')
                        .valueKeys)
                  (value, l10n.discipline(value)),
              ],
              selected: {_discipline},
              onChanged: (v) => setState(() {
                final next = v.firstOrNull ?? _discipline;
                if ((next == 'boulder') != (_discipline == 'boulder')) {
                  // Route and boulder grades are different systems.
                  _grade = null;
                  _pitchGrades.fillRange(0, _pitchGrades.length, null);
                }
                _discipline = next;
              }),
            ),
            formGap,
            gradeField(value: _grade, onChanged: (g) => _grade = g),
            formGap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _length,
                    decoration: InputDecoration(
                      labelText: l10n.routeFormLength,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _checkLength(v, l10n),
                  ),
                ),
                const SizedBox(width: SvaSpace.sm),
                Expanded(
                  child: TextFormField(
                    controller: _pitchCount,
                    decoration: InputDecoration(
                      labelText: l10n.routeFormPitches,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _setPitches,
                    validator: (v) => _checkPitches(v, l10n),
                  ),
                ),
              ],
            ),
            if (_pitches > 1)
              for (final (i, length) in _pitchLengths.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: SvaSpace.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: gradeField(
                          label: l10n.routeFormPitch(i + 1),
                          value: _pitchGrades[i],
                          onChanged: (g) => _pitchGrades[i] = g,
                        ),
                      ),
                      const SizedBox(width: SvaSpace.sm),
                      Expanded(
                        child: TextFormField(
                          controller: length,
                          decoration: InputDecoration(
                            labelText: l10n.routeFormLength,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => _checkLength(v, l10n),
                        ),
                      ),
                    ],
                  ),
                ),
            details('angle', l10n.routeFormAngle),
            details('feature', l10n.routeFormFeatures, multi: true),
            details('hold', l10n.routeFormHolds, multi: true),
            details('protection', l10n.routeFormProtection),
            details('descent', l10n.routeFormDescent),
            formGap,
            ChipGroup(
              label: l10n.routeFormRope,
              options: [
                for (final m in _ropeLengths) ('$m', l10n.routeLength(m)),
              ],
              selected: {if (_rope != null) '$_rope'},
              onChanged: (v) =>
                  setState(() => _rope = int.tryParse(v.firstOrNull ?? '')),
            ),
            formGap,
            TextFormField(
              controller: _firstAscent,
              decoration: InputDecoration(
                labelText: l10n.routeFormFirstAscent,
                hintText: l10n.routeFormFirstAscentHint,
              ),
              maxLength: 200,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SvaSpace.screen),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.routeFormSave),
          ),
        ),
      ),
    );
  }
}
