import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/map_utils.dart';
import '../../core/utils/ui_utils.dart';

/// Widget that displays a map with markers and polylines representing locations.
class LocationMap extends HookConsumerWidget {
  final List<LatLng> points;
  final List<Marker> markers;
  final GoogleMapController? mapController;
  final LatLng? currentPosition;
  final Set<Circle>? circles;
  final Set<Polygon>? polygons;
  final Set<Polyline>? customPolylines;

  const LocationMap({
    super.key,
    required this.points,
    required this.markers,
    required this.mapController,
    this.currentPosition,
    this.circles,
    this.polygons,
    this.customPolylines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = points.isNotEmpty
        ? LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
          )
        : (currentPosition ?? const LatLng(37.7749, -122.4194)); // Default to San Francisco

    // Create polyline from points
    Set<Polyline> polylines = {
      if (points.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: ColorUtils.blueGrey,
          width: 4,
        ),
      if (customPolylines != null)
        ...customPolylines!,
    };

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        print('GoogleMap created successfully');
      },
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 15.0,
      ),
      mapType: MapType.normal,
      markers: Set<Marker>.from(markers),
      polylines: polylines,
      circles: circles ?? {},
      polygons: polygons ?? {},
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
    );
  }
}
