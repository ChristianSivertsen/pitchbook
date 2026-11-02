import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sva/src/app.dart';
import 'package:sva/src/places/location_picker.dart';
import 'package:sva/src/router.dart';
import 'package:sva/src/routes.dart';

/// A 1 × 1 transparent PNG, so the map draws without the network.
final _blank = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blank);
}

void main() {
  testWidgets("M2-9: tapping the map sets the crag's location", (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        mapTilesProvider.overrideWithValue(
          TileLayer(
            urlTemplate: 'fake/{z}/{x}/{y}',
            tileProvider: _BlankTiles(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SvaApp()),
    );
    container.read(routerProvider).go(Routes.cragNew);
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.mapPin), findsNothing);

    // The map opens on the middle of Norway; tap its centre.
    await tester.tap(find.byType(FlutterMap));
    // The map waits to tell a tap from a double tap.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    String field(String label) => tester
        .widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, label),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;
    expect(double.parse(field('Latitude')), closeTo(64.5, 0.01));
    expect(double.parse(field('Longitude')), closeTo(11, 0.01));
    expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);

    // Typed coordinates move the map: tapping its centre now gives them.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitude'),
      '59,92',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitude'),
      '10.5',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FlutterMap));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(double.parse(field('Latitude')), closeTo(59.92, 0.01));
    expect(double.parse(field('Longitude')), closeTo(10.5, 0.01));
  });
}
