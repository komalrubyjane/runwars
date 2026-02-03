import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_tracking_model.dart';

/// Service for detecting loops in GPS tracking data
class LoopDetectionService {
  /// Threshold distance in meters for considering two points as the same location
  static const double LOOP_PROXIMITY_THRESHOLD = 100.0; // 100 meters

  /// Minimum distance in meters to consider it a valid loop
  static const double MINIMUM_LOOP_DISTANCE = 500.0; // 500 meters

  /// Minimum number of points to consider as a loop
  static const int MINIMUM_LOOP_POINTS = 10;

  /// Detects loops in the given GPS points
  /// Returns a list of detected loops
  static List<DetectedLoop> detectLoops(List<GPSPoint> gpsPoints) {
    final List<DetectedLoop> detectedLoops = [];

    if (gpsPoints.length < MINIMUM_LOOP_POINTS) {
      return detectedLoops;
    }

    // For each point, check if we return to a similar location later
    for (int i = 0; i < gpsPoints.length - MINIMUM_LOOP_POINTS; i++) {
      final startPoint = gpsPoints[i];

      // Look for return points in the remaining trajectory
      for (int j = i + MINIMUM_LOOP_POINTS; j < gpsPoints.length; j++) {
        final endPoint = gpsPoints[j];

        final distance = GPSPoint.distanceBetween(startPoint, endPoint);

        // If we return close to a previous point, it's a loop
        if (distance < LOOP_PROXIMITY_THRESHOLD) {
          // Extract the loop points
          final loopPoints = gpsPoints.sublist(i, j + 1);

          // Calculate loop center (average of all points in loop)
          final loopCenter = _calculateCenter(loopPoints);

          // Calculate loop radius (average distance from center)
          final loopRadius = _calculateAverageRadius(loopPoints, loopCenter);

          // Only consider it a valid loop if it covers some distance
          if (loopRadius > MINIMUM_LOOP_DISTANCE / 2) {
            detectedLoops.add(DetectedLoop(
              startIndex: i,
              endIndex: j,
              loopCenter: loopCenter,
              radiusMeters: loopRadius,
              pointsInLoop: loopPoints,
            ));
          }

          // Skip ahead to avoid duplicate loop detection
          i = j;
          break;
        }
      }
    }

    return detectedLoops;
  }

  /// Calculates the center point (average) of a list of GPS points
  static LatLng _calculateCenter(List<GPSPoint> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double sumLat = 0, sumLng = 0;
    for (final point in points) {
      sumLat += point.position.latitude;
      sumLng += point.position.longitude;
    }

    return LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }

  /// Calculates the average radius (distance from center) of points
  static double _calculateAverageRadius(List<GPSPoint> points, LatLng center) {
    if (points.isEmpty) return 0;

    double totalDistance = 0;
    for (final point in points) {
      final tempPoint = GPSPoint(
        position: center,
        timestamp: point.timestamp,
      );
      totalDistance += GPSPoint.distanceBetween(tempPoint, point);
    }

    return totalDistance / points.length;
  }

  /// Checks if a given point is inside any detected loop
  static bool isPointInLoop(GPSPoint point, DetectedLoop loop) {
    final distanceToCenter =
        GPSPoint.distanceBetween(point, GPSPoint(position: loop.loopCenter, timestamp: point.timestamp));
    return distanceToCenter <= loop.radiusMeters;
  }

  /// Gets all loops that a specific point belongs to
  static List<DetectedLoop> getLoopsContainingPoint(
    GPSPoint point,
    List<DetectedLoop> loops,
  ) {
    return loops.where((loop) => isPointInLoop(point, loop)).toList();
  }
}
