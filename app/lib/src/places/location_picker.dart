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
/// committed. Empty when missing; the map is then left out.
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
          userAgentPackageName: 'no.sva.app',
        ),
);

/// Middle of Norway, where the map opens without a better place.
const _norway = LatLng(64.5, 11);

/// A map to place something by tapping it. Shows a pin at [value].
/// Offline, the tiles do not load but taps still set the place.
class LocationPicker extends ConsumerWidget {
  const new({required this.value, required this.onChanged, super.key});

  final LatLon? value;
  final ValueChanged<LatLon> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(mapTilesProvider);
    if (tiles == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = context.svaColors;
    final at = value;
    final point = at == null ? null : LatLng(at.lat, at.lon);
    return Semantics(
      label: l10n.cragFormMap,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(SvaRadius.large),
        child: SizedBox(
          height: 240,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point ?? _norway,
              initialZoom: point == null ? 4 : 13,
              onTap: (_, tapped) =>
                  onChanged((lat: tapped.latitude, lon: tapped.longitude)),
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
              // Mapbox and OpenStreetMap ask for this credit on the map.
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('Mapbox'),
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
