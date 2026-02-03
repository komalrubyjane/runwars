import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_tracking_model.dart';

/// Utility class for creating visual overlays on Google Maps
class MapVisualizationUtils {
  /// Creates circles for detected loops
  static Set<Circle> createLoopCircles(List<DetectedLoop> loops) {
    return loops
        .asMap()
        .entries
        .map(
          (entry) => Circle(
            circleId: CircleId('loop_${entry.key}'),
            center: entry.value.loopCenter,
            radius: entry.value.radiusMeters,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
            onTap: () {
              // Handle tap on loop circle
            },
          ),
        )
        .toSet();
  }

  /// Creates polylines for territory boundary
  static Set<Polyline> createTerritoryBoundary(CapturedTerritory territory) {
    if (territory.boundaryPoints.isEmpty) return {};

    final boundaryLatLngs = territory.boundaryPoints
        .map((point) => point.position)
        .toList();

    // Close the polygon by adding the first point at the end
    if (boundaryLatLngs.isNotEmpty &&
        boundaryLatLngs.last != boundaryLatLngs.first) {
      boundaryLatLngs.add(boundaryLatLngs.first);
    }

    return {
      Polyline(
        polylineId: const PolylineId('territory_boundary'),
        points: boundaryLatLngs,
        color: Colors.green,
        width: 3,
        onTap: () {
          // Handle tap on territory boundary
        },
      ),
    };
  }

  /// Creates a filled polygon overlay for territory
  static Set<Polygon> createTerritoryPolygon(CapturedTerritory territory) {
    if (territory.boundaryPoints.isEmpty) return {};

    final polygonPoints = territory.boundaryPoints
        .map((point) => point.position)
        .toList();

    return {
      Polygon(
        polygonId: const PolygonId('territory_fill'),
        points: polygonPoints,
        fillColor: Colors.green.withOpacity(0.2),
        strokeColor: Colors.green,
        strokeWidth: 2,
        onTap: () {
          // Handle tap on territory polygon
        },
      ),
    };
  }

  /// Creates markers for loop entry and exit points
  static Set<Marker> createLoopMarkers(List<DetectedLoop> loops) {
    final Set<Marker> markers = {};

    for (int i = 0; i < loops.length; i++) {
      final loop = loops[i];
      
      // Entry point marker
      markers.add(
        Marker(
          markerId: MarkerId('loop_${i}_entry'),
          position: loop.pointsInLoop.first.position,
          infoWindow: InfoWindow(title: 'Loop ${i + 1} - Entry'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      // Exit point marker
      markers.add(
        Marker(
          markerId: MarkerId('loop_${i}_exit'),
          position: loop.pointsInLoop.last.position,
          infoWindow: InfoWindow(title: 'Loop ${i + 1} - Exit'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );

      // Center marker
      markers.add(
        Marker(
          markerId: MarkerId('loop_${i}_center'),
          position: loop.loopCenter,
          infoWindow: InfoWindow(
            title: 'Loop ${i + 1} Center',
            snippet: 'Radius: ${loop.radiusMeters.toStringAsFixed(0)}m',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }

    return markers;
  }

  /// Creates polylines for the GPS track with color gradient based on speed
  static Set<Polyline> createSpeedGradientTrack(List<GPSPoint> track) {
    if (track.isEmpty) return {};

    final polylines = <Polyline>{};

    // Create segments with different colors based on speed
    for (int i = 0; i < track.length - 1; i++) {
      final currentPoint = track[i];
      final nextPoint = track[i + 1];

      // Determine color based on speed
      final speed = currentPoint.speed ?? 0;
      final color = _getSpeedColor(speed);

      polylines.add(
        Polyline(
          polylineId: PolylineId('speed_segment_$i'),
          points: [currentPoint.position, nextPoint.position],
          color: color,
          width: 4,
        ),
      );
    }

    return polylines;
  }

  /// Gets color based on speed
  static Color _getSpeedColor(double speedMps) {
    // Convert to km/h for easier understanding
    final speedKmh = speedMps * 3.6;

    if (speedKmh < 5) return Colors.red;
    if (speedKmh < 8) return Colors.orange;
    if (speedKmh < 12) return Colors.yellow;
    if (speedKmh < 15) return Colors.lightGreen;
    return Colors.green;
  }

  /// Creates a heatmap-style visualization of the territory
  static List<Polygon> createHeatmapPolygons(CapturedTerritory territory) {
    // This would require dividing the territory into grid cells
    // and coloring them based on point density
    // For now, returning empty list as this requires more complex logic
    return [];
  }
}
