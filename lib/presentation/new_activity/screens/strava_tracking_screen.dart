import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/enum/activity_type.dart';
import '../../common/core/utils/activity_utils.dart';
import '../../common/core/utils/color_utils.dart';
import '../../common/location/models/gps_tracking_model.dart';
import '../../common/location/view_model/location_view_model.dart';
import '../../common/location/view_model/run_control_view_model.dart';
import '../../common/location/view_model/state/run_control_state.dart';
import '../../common/location/widgets/location_map.dart';
import '../../common/location/widgets/run_control_button.dart';
import '../../common/timer/widgets/timer_sized.dart';
import '../../common/metrics/widgets/metrics.dart';

/// Strava-like activity tracking screen with live metrics
class StravaTrackingScreen extends HookConsumerWidget {
  const StravaTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runControlViewModelProvider);
    final locationState = ref.watch(locationViewModelProvider);
    final locationNotifier = ref.read(locationViewModelProvider.notifier);
    final runNotifier = ref.read(runControlViewModelProvider.notifier);

    // Initialize location on screen load
    useEffect(() {
      _requestLocationPermission(context, locationNotifier);
      locationNotifier.startGettingLocation();
      return () {
        // Cleanup if needed
      };
    }, []);

    final points =
        ref.read(locationViewModelProvider.notifier).savedPositionsLatLng();

    // Create a marker for current position
    final markers = <Marker>[];
    if (locationState.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            locationState.currentPosition!.latitude,
            locationState.currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Activity'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: LocationMap(
                points: points,
                markers: markers,
                mapController: null,
              ),
            ),
          ),
          // Live Metrics Card
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(runState),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _getStatusIcon(runState),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusText(runState),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Metrics (Large Display)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricCard(
                        'DISTANCE',
                        '${(locationState.savedPositions.isNotEmpty ? _calculateDistance(locationState.savedPositions) / 1000 : 0).toStringAsFixed(2)}',
                        'km',
                      ),
                      _buildMetricCard(
                        'TIME',
                        _formatTime(runNotifier.getElapsedSeconds()),
                        '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Step Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STEPS',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${locationState.stepCount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GPS Accuracy Info
                  if (locationState.currentPosition != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📍 GPS Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Accuracy: ${locationState.currentPosition!.accuracy.toStringAsFixed(1)}m',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Lat: ${locationState.currentPosition!.latitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Lon: ${locationState.currentPosition!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Secondary Metrics
                  const Metrics(),
                  const SizedBox(height: 20),

                  // Loop & Territory Info (if available)
                  if (runState.isRunning || runState.isPaused)
                    _buildActivityInfo(locationNotifier, runState),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: RunControlButton(
        onRunStarted: () {
          locationNotifier.startRun();
          runNotifier.startRun();
        },
        onRunStopped: () {
          final stats = locationNotifier.stopRun();
          runNotifier.stopRun(stats);
          _showActivitySummaryDialog(context, ref, stats);
        },
        onRunPaused: () {
          locationNotifier.stopLocationStream();
        },
        onRunResumed: () {
          locationNotifier.resumeLocationStream();
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActivityInfo(
    LocationViewModel locationNotifier,
    RunControlState runState,
  ) {
    final loops = locationNotifier.getDetectedLoops();
    final territory = locationNotifier.getTerritory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Activity Highlights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (loops.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.loop, color: Colors.blue),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loops.length} Loop${loops.length > 1 ? 's' : ''} Detected',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Max radius: ${loops.map((l) => l.radiusMeters).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (territory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area Covered',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(territory.areaSquareMeters / 10000).toStringAsFixed(2)} ha',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(RunControlState state) {
    if (state.isRunning) return Colors.green;
    if (state.isPaused) return Colors.orange;
    return Colors.grey;
  }

  Widget _getStatusIcon(RunControlState state) {
    if (state.isRunning) {
      return const Icon(Icons.fiber_manual_record, color: Colors.white);
    }
    return const Icon(Icons.pause_circle, color: Colors.white);
  }

  String _getStatusText(RunControlState state) {
    if (state.isRunning) return 'RECORDING';
    if (state.isPaused) return 'PAUSED';
    if (state.hasRunEnded) return 'COMPLETED';
    return 'READY';
  }

  double _calculateDistance(List locationData) {
    double total = 0;
    for (int i = 1; i < locationData.length; i++) {
      // Simple haversine approximation
      final lat1 = locationData[i - 1].latitude;
      final lon1 = locationData[i - 1].longitude;
      final lat2 = locationData[i].latitude;
      final lon2 = locationData[i].longitude;

      const R = 6371000; // Earth radius in meters
      final dLat = (lat2 - lat1) * 3.14159 / 180;
      final dLon = (lon2 - lon1) * 3.14159 / 180;
      final a = (1 - (dLat * dLat / 2)) * (1 - (dLon * dLon / 2));
      final c = 2 * (a > 0 ? 1 : -1) * a.toDouble();
      total += R * c;
    }
    return total;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showActivitySummaryDialog(
    BuildContext context,
    WidgetRef ref,
    RunStatistics stats,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogStatRow('Distance', '${(stats.totalDistance / 1000).toStringAsFixed(2)} km'),
            _buildDialogStatRow('Time', _formatDuration(stats.totalTime)),
            _buildDialogStatRow('Avg Speed', '${(stats.averageSpeed * 3.6).toStringAsFixed(2)} km/h'),
            _buildDialogStatRow('Max Speed', '${(stats.maxSpeed * 3.6).toStringAsFixed(2)} km/h'),
            if (stats.totalAltitudeGain > 0)
              _buildDialogStatRow('Elevation Gain', '${stats.totalAltitudeGain.toStringAsFixed(0)} m'),
            if (stats.detectedLoops.isNotEmpty)
              _buildDialogStatRow('Loops', stats.detectedLoops.length.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('View Details'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}m ${seconds}s';
  }

  Future<void> _requestLocationPermission(
    BuildContext context,
    LocationViewModel locationNotifier,
  ) async {
    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Permissions denied
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Location permission denied. Please enable it in settings to track your location.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Permissions denied forever, open settings
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📍 Location Permission Required'),
              content: const Text(
                'This app needs access to your real GPS location to track your runs accurately. Please enable "Location" permission in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Permission granted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Location access granted! Your GPS is now being tracked.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Get initial position with best accuracy
        try {
          await Geolocator.getCurrentPosition(
            forceAndroidLocationManager: false,
          );
        } catch (e) {
          print('Error getting initial position: $e');
        }
      }
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Permission already granted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Using your real GPS location for tracking'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
