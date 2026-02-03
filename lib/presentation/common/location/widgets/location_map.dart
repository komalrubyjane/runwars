import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget that displays a map with markers and polylines representing locations.
/// Supports polyline color per player, closed-loop polygons, and animated runner marker.
class LocationMap extends HookConsumerWidget {
  final List<LatLng> points;
  final List<Marker> markers;
  final GoogleMapController? mapController;
  final LatLng? currentPosition;
  final Set<Circle>? circles;
  final Set<Polygon>? polygons;
  final Set<Polyline>? customPolylines;
  /// Polyline color for current player's path (default: Strava orange)
  final int polylineColorValue;
  /// Closed-loop polygons to fill (from DetectedLoop)
  final List<List<LatLng>>? closedLoopPolygons;
  /// Fill color for closed loops (default: Strava orange with alpha)
  final int closedLoopColorValue;

  const LocationMap({
    super.key,
    required this.points,
    required this.markers,
    required this.mapController,
    this.currentPosition,
    this.circles,
    this.polygons,
    this.customPolylines,
    this.polylineColorValue = 0xFFFC4C02,
    this.closedLoopPolygons,
    this.closedLoopColorValue = 0x33FC4C02,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = points.isNotEmpty
        ? LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
          )
        : (currentPosition ?? const LatLng(37.7749, -122.4194)); // Default to San Francisco

    // Create polyline from points with player color
    Set<Polyline> polylines = {
      if (points.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Color(polylineColorValue),
          width: 5,
        ),
      if (customPolylines != null)
        ...customPolylines!,
    };

    // Closed-loop polygons (filled regions)
    final loopPolygons = <Polygon>{};
    if (closedLoopPolygons != null) {
      for (var i = 0; i < closedLoopPolygons!.length; i++) {
        final pts = closedLoopPolygons![i];
        if (pts.length >= 3) {
          loopPolygons.add(
            Polygon(
              polygonId: PolygonId('loop_$i'),
              points: pts,
              fillColor: Color(closedLoopColorValue),
              strokeColor: Color(polylineColorValue),
              strokeWidth: 3,
            ),
          );
        }
      }
    }
    final allPolygons = {...?polygons, ...loopPolygons};

    return GoogleMap(
      onMapCreated: (_) {},
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 15.0,
      ),
      mapType: MapType.normal,
      markers: Set<Marker>.from(markers),
      polylines: polylines,
      circles: circles ?? {},
      polygons: allPolygons,
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
