import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a single GPS point in a run
class GPSPoint {
  final LatLng position;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final double? altitude;

  const GPSPoint({
    required this.position,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.altitude,
  });

  /// Calculate distance between two GPS points using Haversine formula
  static double distanceBetween(GPSPoint point1, GPSPoint point2) {
    const int earthRadiusMeters = 6371000;

    final lat1 = _toRad(point1.position.latitude);
    final lat2 = _toRad(point2.position.latitude);
    final deltaLat = _toRad(point2.position.latitude - point1.position.latitude);
    final deltaLng = _toRad(point2.position.longitude - point1.position.longitude);

    final a = (1 - _cos(deltaLat)) / 2 +
        _cos(lat1) * _cos(lat2) * (1 - _cos(deltaLng)) / 2;
    final c = 2 * _asin(_sqrt(_min(1.0, a)));

    return earthRadiusMeters * c;
  }

  static double _toRad(double deg) => deg * (3.141592653589793 / 180);
  static double _cos(double rad) => (1 - rad * rad / 2).clamp(-1, 1);
  static double _asin(double x) => 2 * (x / (1 + x * x / 6)).clamp(-1, 1);
  static double _sqrt(double x) => x > 0 ? (x + 1 / x) / 2 : 0;
  static double _min(double a, double b) => a < b ? a : b;
}

/// Represents a detected loop in the run
class DetectedLoop {
  final int startIndex;
  final int endIndex;
  final LatLng loopCenter;
  final double radiusMeters;
  final List<GPSPoint> pointsInLoop;

  const DetectedLoop({
    required this.startIndex,
    required this.endIndex,
    required this.loopCenter,
    required this.radiusMeters,
    required this.pointsInLoop,
  });
}

/// Represents captured territory (area) during a run
class CapturedTerritory {
  /// List of GPS points that form the territory boundary
  final List<GPSPoint> boundaryPoints;

  /// Approximate area in square meters
  final double areaSquareMeters;

  /// List of points inside the territory
  final List<GPSPoint> allPointsInTerritory;

  const CapturedTerritory({
    required this.boundaryPoints,
    required this.areaSquareMeters,
    required this.allPointsInTerritory,
  });
}

/// Represents run statistics
class RunStatistics {
  final double totalDistance;
  final Duration totalTime;
  final double averageSpeed;
  final double maxSpeed;
  final double totalAltitudeGain;
  final int pointCount;
  final List<DetectedLoop> detectedLoops;
  final CapturedTerritory? territory;

  const RunStatistics({
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.totalAltitudeGain,
    required this.pointCount,
    required this.detectedLoops,
    this.territory,
  });
}
