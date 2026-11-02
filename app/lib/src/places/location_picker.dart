import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/l10n/app_localizations.dart';
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
  const new({required this.value, required this.onChanged, super.key});

  final LatLon? value;
  final ValueChanged<LatLon> onChanged;

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
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final at = widget.value;
    final point = at == null ? null : LatLng(at.lat, at.lon);
    return Semantics(
      container: true,
      label: l10n.cragFormMap,
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
