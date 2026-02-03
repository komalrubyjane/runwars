import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_tracking_model.dart';

/// Service for capturing and analyzing territory (area) covered during a run
class TerritoryCaptureService {
  /// Minimum points to calculate territory
  static const int MINIMUM_POINTS = 5;

  /// Grid cell size in meters for territory discretization
  static const double GRID_CELL_SIZE = 10.0;

  /// Captures territory from GPS points and calculates area
  static CapturedTerritory captureTerritory(List<GPSPoint> gpsPoints) {
    if (gpsPoints.length < MINIMUM_POINTS) {
      return CapturedTerritory(
        boundaryPoints: gpsPoints,
        areaSquareMeters: 0,
        allPointsInTerritory: gpsPoints,
      );
    }

    // Use convex hull to get boundary points (minimal area enclosing the path)
    final boundaryPoints = _convexHull(gpsPoints);

    // Calculate area using Shoelace formula
    final areaSquareMeters = _calculatePolygonArea(boundaryPoints);

    return CapturedTerritory(
      boundaryPoints: boundaryPoints,
      areaSquareMeters: areaSquareMeters,
      allPointsInTerritory: gpsPoints,
    );
  }

  /// Calculates convex hull of GPS points using Graham's scan algorithm
  static List<GPSPoint> _convexHull(List<GPSPoint> points) {
    if (points.length <= 3) return points;

    // Convert to 2D points for calculation
    final converted = points
        .map((p) => _Point(p.position.latitude, p.position.longitude, p))
        .toList();

    // Sort points lexicographically
    converted.sort((a, b) {
      if (a.x != b.x) return (a.x - b.x).toInt();
      return (a.y - b.y).toInt();
    });

    // Build lower hull
    final List<_Point> lower = [];
    for (final p in converted) {
      while (lower.length >= 2 &&
          _crossProduct(lower[lower.length - 2], lower[lower.length - 1], p) <=
              0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    // Build upper hull
    final List<_Point> upper = [];
    for (int i = converted.length - 1; i >= 0; i--) {
      final p = converted[i];
      while (upper.length >= 2 &&
          _crossProduct(upper[upper.length - 2], upper[upper.length - 1], p) <=
              0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    // Remove last point of each half because it's repeated
    lower.removeLast();
    upper.removeLast();

    // Concatenate lower and upper hull
    lower.addAll(upper);

    return lower.map((p) => p.originalPoint).toList();
  }

  /// Calculates area of polygon using Shoelace formula
  /// Returns area in square meters (approximated)
  static double _calculatePolygonArea(List<GPSPoint> polygon) {
    if (polygon.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      // Use shoelace formula (simplified for lat/lng)
      area += p1.position.latitude * p2.position.longitude;
      area -= p2.position.latitude * p1.position.longitude;
    }

    area = area.abs() / 2;

    // Convert from lat/lng degrees squared to approximate square meters
    // At equator: 1 degree ≈ 111,320 meters
    const double meterPerDegree = 111320;
    final avgLatitude = polygon.fold<double>(0, (sum, p) => sum + p.position.latitude) / polygon.length;
    final latCorrectionFactor = cos(avgLatitude * pi / 180);

    return area * meterPerDegree * meterPerDegree * latCorrectionFactor;
  }

  /// Calculates cross product of three points
  static double _crossProduct(_Point o, _Point a, _Point b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }

  /// Checks if a point is inside a polygon using ray casting algorithm
  static bool isPointInTerritory(GPSPoint point, CapturedTerritory territory) {
    return _isPointInPolygon(point.position, territory.boundaryPoints.map((p) => p.position).toList());
  }

  /// Checks if a point is inside a polygon using ray casting
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      final condition = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);

      if (condition) isInside = !isInside;
      j = i;
    }

    return isInside;
  }

  /// Calculates the percentage of territory covered
  /// by the provided GPS points
  static double calculateCoverageDensity(CapturedTerritory territory) {
    if (territory.boundaryPoints.isEmpty || territory.areaSquareMeters == 0) {
      return 0;
    }

    // Simple density calculation: number of points per square meter
    return territory.allPointsInTerritory.length / territory.areaSquareMeters * 1000;
  }
}

/// Helper class for 2D point operations
class _Point {
  double x, y;
  GPSPoint originalPoint;

  _Point(this.x, this.y, this.originalPoint);
}
