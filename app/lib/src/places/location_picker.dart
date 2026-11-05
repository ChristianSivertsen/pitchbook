import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
import 'package:sva/src/places/form_parts.dart';
import 'package:sva_data/sva_data.dart' show LatLon;
import 'package:sva_ui/sva_ui.dart';

/// The Mapbox access token, given at build time with
/// `--dart-define-from-file=mapbox.json` (or `--dart-define`), never
/// committed. A public `pk.` token: restrict it and set a usage alert in
/// the Mapbox dashboard. Empty when missing; the map is then left out.
const _mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// Where map tiles come from, or `null` when there is no token: the forms
/// then only take typed coordinates. Tests override it with fake tiles.
final Provider<TileLayer?> mapTilesProvider = Provider(
  (ref) => _mapboxToken.isEmpty
      ? null
      : TileLayer(
          // Mapbox's Outdoors style: terrain, contours and trails.
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/'
              '256/{z}/{x}/{y}@2x?access_token={accessToken}',
          additionalOptions: const {'accessToken': _mapboxToken},
          userAgentPackageName: 'com.christiansivertsen.sva',
        ),
);

/// Middle of Norway, where the map opens without a better place.
const _norway = LatLng(64.5, 11);

/// Height of the map in a form.
const _mapHeight = 240.0;

/// Zoom for a known place: a crag and its surroundings.
const _placeZoom = 13.0;

/// A map to place something by tapping it. Shows a pin at [value] and
/// moves to it when it is typed in. Offline, the tiles do not load but
/// taps still set the place.
class LocationPicker extends ConsumerStatefulWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final LatLon? value;
  final ValueChanged<LatLon> onChanged;

  /// What a screen reader says the map is for.
  final String label;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  final _controller = MapController();

  /// The place the user last tapped. A tap must not move the map under
  /// their finger; only typed coordinates do.
  LatLon? _tapped;

  @override
  void didUpdateWidget(LocationPicker old) {
    super.didUpdateWidget(old);
    final at = widget.value;
    if (at != null && at != old.value && at != _tapped) {
      _controller.move(LatLng(at.lat, at.lon), _placeZoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = ref.watch(mapTilesProvider);
    if (tiles == null) return const SizedBox.shrink();
    final colors = context.svaColors;
    final at = widget.value;
    final point = at == null ? null : LatLng(at.lat, at.lon);
    return Semantics(
      container: true,
      label: widget.label,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(SvaRadius.large),
        child: SizedBox(
          height: _mapHeight,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: point ?? _norway,
              initialZoom: point == null ? 4 : _placeZoom,
              onTap: (_, tapped) {
                final place = (lat: tapped.latitude, lon: tapped.longitude);
                _tapped = place;
                widget.onChanged(place);
              },
            ),
            children: [
              tiles,
              if (point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: SvaSpace.xxl,
                      height: SvaSpace.xxl,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        LucideIcons.mapPin,
                        color: colors.granite,
                        size: SvaSpace.xxl,
                      ),
                    ),
                  ],
                ),
              // Mapbox and OpenStreetMap ask for a visible credit.
              const SimpleAttributionWidget(
                source: Text('© Mapbox © OpenStreetMap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A place in a form: the map to tap, when there is one, and typed
/// decimal degrees. The form owns [lat] and [lon] and reads them with
/// [locationOf].
class LocationFields extends ConsumerWidget {
  const new({
    required this.lat,
    required this.lon,
    required this.mapLabel,
    required this.onChanged,
    super.key,
  });

  final TextEditingController lat;
  final TextEditingController lon;

  /// What a screen reader says the map is for.
  final String mapLabel;

  /// Called when either coordinate changes.
  final VoidCallback onChanged;

  /// Both coordinates, or `null` unless both are numbers.
  static LatLon? locationOf(
    TextEditingController lat,
    TextEditingController lon,
  ) {
    final la = parseDecimal(lat.text);
    final lo = parseDecimal(lon.text);
    return la == null || lo == null ? null : (lat: la, lon: lo);
  }

  String? _check(AppLocalizations l10n) {
    if (lat.text.trim().isEmpty && lon.text.trim().isEmpty) return null;
    final at = locationOf(lat, lon);
    return at == null || at.lat.abs() > 90 || at.lon.abs() > 180
        ? l10n.cragFormLocationInvalid
        : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Widget field(TextEditingController controller, String label) => Expanded(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        // Moves the pin on the map as you type.
        onChanged: (_) => onChanged(),
        validator: (_) => _check(l10n),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationPicker(
          value: locationOf(lat, lon),
          label: mapLabel,
          onChanged: (at) {
            lat.text = at.lat.toStringAsFixed(5);
            lon.text = at.lon.toStringAsFixed(5);
            onChanged();
          },
        ),
        const SizedBox(height: SvaSpace.xs),
        Text(
          ref.watch(mapTilesProvider) == null
              ? l10n.cragFormLocationHint
              : l10n.cragFormLocationHintMap,
          style: context.svaText.caption.copyWith(
            color: context.svaColors.textMuted,
          ),
        ),
        const SizedBox(height: SvaSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SvaSpace.sm,
          children: [
            field(lat, l10n.cragFormLatitude),
            field(lon, l10n.cragFormLongitude),
          ],
        ),
      ],
    );
  }
}
