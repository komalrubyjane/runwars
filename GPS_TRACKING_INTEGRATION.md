# GPS Tracking, Loop Detection, and Territory Capture Integration Guide

This document explains the new GPS tracking features integrated into the RunFlutterRun app.

## Overview

The app now includes:
1. **GPS Tracking** - Real-time location tracking with detailed metrics
2. **Start/Stop Run Controls** - Manage run sessions with pause/resume functionality
3. **Loop Detection** - Automatically detect when runners complete loops
4. **Territory Capture** - Calculate area covered during runs

## Architecture

### Data Models

#### GPSPoint
Represents a single GPS location with metadata:
```dart
GPSPoint(
  position: LatLng(latitude, longitude),
  timestamp: DateTime.now(),
  accuracy: 5.0,  // meters
  speed: 3.2,     // m/s
  altitude: 125.0 // meters
)
```

#### DetectedLoop
Represents a completed loop in the run:
```dart
DetectedLoop(
  startIndex: 10,
  endIndex: 150,
  loopCenter: LatLng(lat, lng),
  radiusMeters: 500.0,
  pointsInLoop: [GPSPoint, ...],
)
```

#### CapturedTerritory
Represents the area covered during a run:
```dart
CapturedTerritory(
  boundaryPoints: [GPSPoint, ...],
  areaSquareMeters: 15000.0,
  allPointsInTerritory: [GPSPoint, ...],
)
```

#### RunStatistics
Comprehensive statistics from a completed run:
```dart
RunStatistics(
  totalDistance: 5200.0,      // meters
  totalTime: Duration(minutes: 30),
  averageSpeed: 2.9,          // m/s
  maxSpeed: 5.1,              // m/s
  totalAltitudeGain: 120.0,   // meters
  pointCount: 150,
  detectedLoops: [DetectedLoop, ...],
  territory: CapturedTerritory(...),
)
```

## Services

### 1. LoopDetectionService

Detects loops in GPS tracks using proximity analysis.

**Configuration:**
- `LOOP_PROXIMITY_THRESHOLD = 100m` - Distance to consider points as same location
- `MINIMUM_LOOP_DISTANCE = 500m` - Minimum loop size
- `MINIMUM_LOOP_POINTS = 10` - Minimum points to form a loop

**Key Methods:**
```dart
// Detect all loops in a track
List<DetectedLoop> loops = LoopDetectionService.detectLoops(gpsPoints);

// Check if point is in a specific loop
bool inLoop = LoopDetectionService.isPointInLoop(point, loop);

// Get all loops containing a point
List<DetectedLoop> containingLoops = 
    LoopDetectionService.getLoopsContainingPoint(point, loops);
```

### 2. TerritoryCaptureService

Calculates area covered using convex hull and polygon algorithms.

**Key Methods:**
```dart
// Capture territory from GPS points
CapturedTerritory territory = TerritoryCaptureService.captureTerritory(gpsPoints);

// Check if point is within captured territory
bool inTerritory = TerritoryCaptureService.isPointInTerritory(point, territory);

// Calculate coverage density
double density = TerritoryCaptureService.calculateCoverageDensity(territory);
```

### 3. LocationViewModel (Enhanced)

**New Methods:**
```dart
// Start a new run
void startRun()

// Stop current run and get statistics
RunStatistics stopRun()

// Check if run is active
bool isRunActive()

// Get detected loops
List<DetectedLoop> getDetectedLoops()

// Get captured territory
CapturedTerritory? getTerritory()

// Get all GPS points
List<GPSPoint> getGPSTrack()
```

### 4. RunControlViewModel

Manages run state (started, running, paused, stopped).

**Key Methods:**
```dart
// Control methods
void startRun()
void pauseRun()
void resumeRun()
void stopRun(RunStatistics statistics)
void resetRun()

// State queries
RunStatus getRunStatus()
int getElapsedSeconds()
```

## UI Components

### 1. RunControlButton

Widget providing visual start/pause/stop controls.

```dart
RunControlButton(
  onRunStarted: () {
    print('Run started');
  },
  onRunStopped: () {
    print('Run completed');
  },
  onRunPaused: () {
    print('Run paused');
  },
  onRunResumed: () {
    print('Run resumed');
  },
)
```

**Features:**
- Visual status indicator (Ready/Active/Paused/Finished)
- Context-aware buttons
- Automatic state management

### 2. GPSTrackingStats

Widget displaying all tracking statistics.

```dart
GPSTrackingStats(
  statistics: runStatistics,
)
```

**Displays:**
- Basic stats (distance, time, speed)
- Altitude gain
- Loop detection results
- Territory coverage area and density

### 3. MapVisualizationUtils

Static utilities for visualizing data on Google Maps.

```dart
// Create visual loop circles
Set<Circle> loops = MapVisualizationUtils.createLoopCircles(detectedLoops);

// Create territory boundary
Set<Polyline> boundary = MapVisualizationUtils.createTerritoryBoundary(territory);

// Create filled territory
Set<Polygon> territory = MapVisualizationUtils.createTerritoryPolygon(territory);

// Create loop markers
Set<Marker> markers = MapVisualizationUtils.createLoopMarkers(detectedLoops);

// Create speed-based track coloring
Set<Polyline> track = MapVisualizationUtils.createSpeedGradientTrack(gpsPoints);
```

## Integration Example

### Basic Run Tracking

```dart
class ActivityTrackingScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runControl = ref.watch(runControlViewModelProvider);
    final runControlNotifier = ref.read(runControlViewModelProvider.notifier);
    final locationNotifier = ref.read(locationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Run Tracker')),
      body: Column(
        children: [
          // Run controls
          RunControlButton(
            onRunStarted: () {
              locationNotifier.startRun();
              print('Tracking started');
            },
            onRunStopped: () {
              final stats = locationNotifier.stopRun();
              print('Distance: ${stats.totalDistance}m');
              print('Loops: ${stats.detectedLoops.length}');
              print('Area: ${stats.territory?.areaSquareMeters}m²');
            },
          ),
          const SizedBox(height: 16),
          // Statistics display
          if (runControl.finalStatistics != null)
            Expanded(
              child: GPSTrackingStats(
                statistics: runControl.finalStatistics,
              ),
            ),
        ],
      ),
    );
  }
}
```

### Advanced Map Visualization

```dart
class AdvancedMapScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationViewModelProvider);
    final locationNotifier = ref.read(locationViewModelProvider.notifier);

    // Get current tracking data
    final loops = locationNotifier.getDetectedLoops();
    final territory = locationNotifier.getTerritory();
    final track = locationNotifier.getGPSTrack();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(0, 0),
        zoom: 15,
      ),
      // Add visual overlays
      circles: MapVisualizationUtils.createLoopCircles(loops),
      polylines: {
        ...MapVisualizationUtils.createTerritoryBoundary(territory ?? CapturedTerritory(
          boundaryPoints: [],
          areaSquareMeters: 0,
          allPointsInTerritory: [],
        )),
        ...MapVisualizationUtils.createSpeedGradientTrack(track),
      },
      polygons: MapVisualizationUtils.createTerritoryPolygon(territory ?? CapturedTerritory(
        boundaryPoints: [],
        areaSquareMeters: 0,
        allPointsInTerritory: [],
      )),
      markers: MapVisualizationUtils.createLoopMarkers(loops),
    );
  }
}
```

## Algorithm Details

### Loop Detection Algorithm

1. **Iterate through all GPS points**
2. **For each point, look ahead for return points**
3. **When distance between points < 100m, mark as potential loop**
4. **Validate loop is large enough (radius > 250m)**
5. **Extract loop center and radius**

**Time Complexity:** O(n²) where n = number of GPS points
**Space Complexity:** O(m) where m = number of detected loops

### Territory Capture Algorithm

Uses **Graham's Scan** for convex hull:

1. **Sort points lexicographically**
2. **Build lower hull by scanning left-to-right**
3. **Build upper hull by scanning right-to-left**
4. **Combine hulls to form convex boundary**

**Area Calculation:** Uses **Shoelace Formula** with lat/lng conversion

**Time Complexity:** O(n log n) for sorting + O(n) for hull = **O(n log n)**
**Space Complexity:** O(n) for input + O(h) for hull where h ≤ n

## Configuration

### Loop Detection Thresholds

Modify in `loop_detection_service.dart`:
```dart
static const double LOOP_PROXIMITY_THRESHOLD = 100.0;  // meters
static const double MINIMUM_LOOP_DISTANCE = 500.0;     // meters
static const int MINIMUM_LOOP_POINTS = 10;
```

### Territory Grid Size

Modify in `territory_capture_service.dart`:
```dart
static const double GRID_CELL_SIZE = 10.0;  // meters
```

## Performance Considerations

1. **GPS Point Throttling:** Consider reducing point collection rate for long runs
2. **Loop Detection:** Run in background isolate for runs > 1000 points
3. **Territory Calculation:** Cache convex hull during run
4. **Memory:** Clear old runs to prevent memory buildup

## Testing

### Unit Test Examples

```dart
test('Loop detection identifies basic loop', () {
  final points = [...]; // Create circular path
  final loops = LoopDetectionService.detectLoops(points);
  
  expect(loops.length, 1);
  expect(loops[0].radiusMeters, greaterThan(200));
});

test('Territory area calculation is reasonable', () {
  final points = [...]; // Create square path
  final territory = TerritoryCaptureService.captureTerritory(points);
  
  expect(territory.areaSquareMeters, greaterThan(0));
  expect(territory.boundaryPoints.length, lessThanOrEqualTo(points.length));
});
```

## Future Enhancements

1. **Heatmap visualization** - Show high-traffic areas
2. **Segment analysis** - Break down runs into segments
3. **Elevation profiles** - Visualize altitude changes
4. **Social sharing** - Share territory and loops with friends
5. **Challenges** - Create loop/area-based challenges
6. **Navigation** - Turn-by-turn directions for explored territory

## Troubleshooting

### GPS Points Not Recording
- Check location permissions in AndroidManifest.xml
- Verify `startGettingLocation()` is called
- Check if run is actually started with `startRun()`

### Loops Not Detected
- Verify `MINIMUM_LOOP_POINTS` threshold
- Check `LOOP_PROXIMITY_THRESHOLD` is appropriate for area
- Ensure GPS accuracy is reasonable (< 20m)

### Territory Boundary Incorrect
- Check if enough points recorded (minimum 5)
- Verify points cover the intended area
- Try adjusting grid cell size

## References

- Graham Scan Algorithm: https://en.wikipedia.org/wiki/Graham_scan
- Shoelace Formula: https://en.wikipedia.org/wiki/Shoelace_formula
- Haversine Formula: https://en.wikipedia.org/wiki/Haversine_formula
- Point-in-polygon (Ray Casting): https://en.wikipedia.org/wiki/Point_in_polygon
