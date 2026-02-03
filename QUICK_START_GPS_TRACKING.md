# Quick Start Guide - GPS Tracking Integration

## What You Just Integrated

You now have 4 major features in your app:

### 1. GPS Tracking 🗺️
Real-time tracking of runner location with detailed metrics (speed, altitude, accuracy).

### 2. Start/Stop Controls ▶️⏸️⏹️
UI controls to manage run sessions with pause/resume functionality.

### 3. Loop Detection 🔄
Automatically detects when runners complete loops/circles during their run.

### 4. Territory Capture 📍
Calculates and visualizes the area covered during a run.

---

## File Structure

### Core Models
- `lib/presentation/common/location/models/gps_tracking_model.dart` - Data models
  - `GPSPoint` - Single location with metadata
  - `DetectedLoop` - Information about detected loops
  - `CapturedTerritory` - Area covered during run
  - `RunStatistics` - Complete run metrics

### Services
- `lib/presentation/common/location/services/loop_detection_service.dart`
  - `LoopDetectionService` - Detects loops in GPS data
  
- `lib/presentation/common/location/services/territory_capture_service.dart`
  - `TerritoryCaptureService` - Calculates area covered

### State Management
- `lib/presentation/common/location/view_model/location_view_model.dart` (Enhanced)
  - New methods: `startRun()`, `stopRun()`, `getDetectedLoops()`, `getTerritory()`
  
- `lib/presentation/common/location/view_model/run_control_view_model.dart`
  - `RunControlViewModel` - Manages run state
  
- `lib/presentation/common/location/view_model/state/run_control_state.dart`
  - `RunControlState` - Run state data class

### UI Components
- `lib/presentation/common/location/widgets/run_control_button.dart`
  - `RunControlButton` - Visual start/pause/stop controls
  
- `lib/presentation/common/location/widgets/gps_tracking_stats.dart`
  - `GPSTrackingStats` - Display tracking statistics
  
- `lib/presentation/common/location/widgets/map_visualization_utils.dart`
  - `MapVisualizationUtils` - Utilities for map overlays

### Example
- `lib/presentation/new_activity/screens/gps_tracking_example_screen.dart`
  - Complete example showing all features in action

---

## How to Use

### Basic: Just Start Tracking

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:your_app/presentation/common/location/view_model/location_view_model.dart';
import 'package:your_app/presentation/common/location/view_model/run_control_view_model.dart';

class SimpleRunScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationNotifier = ref.read(locationViewModelProvider.notifier);
    final runControl = ref.watch(runControlViewModelProvider);

    return Scaffold(
      floatingActionButton: ElevatedButton(
        onPressed: () {
          locationNotifier.startRun();
        },
        child: const Text('Start Run'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Status: ${runControl.isRunning ? 'Running' : 'Stopped'}'),
            ElevatedButton(
              onPressed: () {
                final stats = locationNotifier.stopRun();
                print('Distance: ${stats.totalDistance}m');
                print('Time: ${stats.totalTime}');
              },
              child: const Text('Stop Run'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Advanced: Full-Featured Screen

Use the example screen as a reference:
```dart
GPSTrackingExampleScreen()
```

This shows:
- ✅ Map visualization with loops and territory
- ✅ Real-time statistics
- ✅ Loop details
- ✅ Territory information
- ✅ Control buttons

---

## Integration Steps

### Step 1: Add Providers to Your Screen

```dart
final runState = ref.watch(runControlViewModelProvider);
final locationState = ref.watch(locationViewModelProvider);
final locationNotifier = ref.read(locationViewModelProvider.notifier);
final runNotifier = ref.read(runControlViewModelProvider.notifier);
```

### Step 2: Add Run Controls

```dart
RunControlButton(
  onRunStarted: () {
    locationNotifier.startRun();
  },
  onRunStopped: () {
    final stats = locationNotifier.stopRun();
    runNotifier.stopRun(stats);
  },
)
```

### Step 3: Get GPS Data

```dart
// Get detected loops
final loops = locationNotifier.getDetectedLoops();

// Get captured territory
final territory = locationNotifier.getTerritory();

// Get all GPS points
final track = locationNotifier.getGPSTrack();
```

### Step 4: Visualize on Map

```dart
final circles = MapVisualizationUtils.createLoopCircles(loops);
final polygons = MapVisualizationUtils.createTerritoryPolygon(territory);
final markers = MapVisualizationUtils.createLoopMarkers(loops);
final speedTrack = MapVisualizationUtils.createSpeedGradientTrack(track);

GoogleMap(
  circles: circles,
  polygons: polygons,
  markers: markers,
  polylines: speedTrack,
)
```

### Step 5: Display Statistics

```dart
if (runState.finalStatistics != null) {
  GPSTrackingStats(statistics: runState.finalStatistics)
}
```

---

## Key Methods Reference

### LocationViewModel
```dart
locationNotifier.startRun()                    // Start new run
locationNotifier.stopRun()                     // Stop run, returns RunStatistics
locationNotifier.isRunActive()                 // Check if running
locationNotifier.getDetectedLoops()            // Get loop list
locationNotifier.getTerritory()                // Get territory or null
locationNotifier.getGPSTrack()                 // Get all GPS points
```

### RunControlViewModel
```dart
runNotifier.startRun()                         // Start run
runNotifier.pauseRun()                         // Pause run
runNotifier.resumeRun()                        // Resume run
runNotifier.stopRun(stats)                     // Stop run
runNotifier.resetRun()                         // Reset state
runNotifier.getRunStatus()                     // Get current status
runNotifier.getElapsedSeconds()                // Get elapsed time
```

### Loop Detection
```dart
LoopDetectionService.detectLoops(points)       // Detect loops
LoopDetectionService.isPointInLoop(point, loop) // Check if point in loop
```

### Territory Capture
```dart
TerritoryCaptureService.captureTerritory(points) // Calculate territory
TerritoryCaptureService.isPointInTerritory(point, territory)
TerritoryCaptureService.calculateCoverageDensity(territory)
```

### Map Visualization
```dart
MapVisualizationUtils.createLoopCircles(loops)
MapVisualizationUtils.createTerritoryBoundary(territory)
MapVisualizationUtils.createTerritoryPolygon(territory)
MapVisualizationUtils.createLoopMarkers(loops)
MapVisualizationUtils.createSpeedGradientTrack(track)
```

---

## Data Models

### GPSPoint
```dart
GPSPoint(
  position: LatLng(latitude, longitude),
  timestamp: DateTime.now(),
  accuracy: 5.0,      // meters
  speed: 3.2,         // m/s
  altitude: 125.0,    // meters
)
```

### DetectedLoop
```dart
DetectedLoop(
  startIndex: 10,
  endIndex: 150,
  loopCenter: LatLng(lat, lng),
  radiusMeters: 500.0,
  pointsInLoop: [GPSPoint, ...],
)
```

### CapturedTerritory
```dart
CapturedTerritory(
  boundaryPoints: [GPSPoint, ...],
  areaSquareMeters: 15000.0,
  allPointsInTerritory: [GPSPoint, ...],
)
```

### RunStatistics
```dart
RunStatistics(
  totalDistance: 5200.0,           // meters
  totalTime: Duration(...),
  averageSpeed: 2.9,               // m/s
  maxSpeed: 5.1,                   // m/s
  totalAltitudeGain: 120.0,        // meters
  pointCount: 150,
  detectedLoops: [DetectedLoop, ...],
  territory: CapturedTerritory(...),
)
```

---

## Common Patterns

### Display Statistics After Run
```dart
final runState = ref.watch(runControlViewModelProvider);

if (runState.finalStatistics != null) {
  final stats = runState.finalStatistics!;
  print('Distance: ${(stats.totalDistance / 1000).toStringAsFixed(2)} km');
  print('Time: ${stats.totalTime.inMinutes} minutes');
  print('Loops: ${stats.detectedLoops.length}');
  print('Area: ${(stats.territory?.areaSquareMeters ?? 0) / 10000} hectares');
}
```

### Show Loops on Map
```dart
final loops = locationNotifier.getDetectedLoops();
final circles = MapVisualizationUtils.createLoopCircles(loops);
final markers = MapVisualizationUtils.createLoopMarkers(loops);

GoogleMap(
  circles: circles,
  markers: markers,
)
```

### Show Territory
```dart
final territory = locationNotifier.getTerritory();
if (territory != null) {
  final polygons = MapVisualizationUtils.createTerritoryPolygon(territory);
  final boundary = MapVisualizationUtils.createTerritoryBoundary(territory);
  
  GoogleMap(
    polygons: polygons,
    polylines: boundary,
  )
}
```

---

## Testing in Simulator

### Android Emulator
```bash
flutter run
# Run should start tracking location updates
```

### Use Mock Location Provider
If simulator doesn't have location:
1. Go to Extended Controls in emulator
2. Set Location to specific coordinates
3. See GPS data stream in

 your app

---

## Next Steps

1. **Add to Existing Screens**: Integrate `RunControlButton` into your activity screens
2. **Customize Visualization**: Adjust colors and styles in `MapVisualizationUtils`
3. **Fine-tune Detection**: Adjust thresholds in service constants
4. **Add Persistence**: Save RunStatistics to database
5. **Create Challenges**: Use loops/territory for leaderboards

---

## Need More Help?

See full documentation: [GPS_TRACKING_INTEGRATION.md](GPS_TRACKING_INTEGRATION.md)

See working example: [gps_tracking_example_screen.dart](lib/presentation/new_activity/screens/gps_tracking_example_screen.dart)
