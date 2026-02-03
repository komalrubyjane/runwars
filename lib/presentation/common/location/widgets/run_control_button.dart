import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../view_model/location_view_model.dart';
import '../view_model/run_control_view_model.dart';

/// Widget that displays start/stop/pause/resume controls for a run
class RunControlButton extends HookConsumerWidget {
  final VoidCallback? onRunStarted;
  final VoidCallback? onRunStopped;
  final VoidCallback? onRunPaused;
  final VoidCallback? onRunResumed;

  const RunControlButton({
    super.key,
    this.onRunStarted,
    this.onRunStopped,
    this.onRunPaused,
    this.onRunResumed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runControlState = ref.watch(runControlViewModelProvider);
    final runControlNotifier = ref.read(runControlViewModelProvider.notifier);
    final locationNotifier = ref.read(locationViewModelProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(runControlState.isRunning, runControlState.isPaused),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(runControlState.isRunning, runControlState.isPaused, runControlState.hasRunEnded),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start/Resume button
            if (!runControlState.hasRunEnded)
              FloatingActionButton(
                onPressed: () {
                  if (!runControlState.hasRunStarted) {
                    // Start new run
                    runControlNotifier.startRun();
                    locationNotifier.startRun();
                    onRunStarted?.call();
                  } else if (runControlState.isPaused) {
                    // Resume paused run
                    runControlNotifier.resumeRun();
                    locationNotifier.resumeLocationStream();
                    onRunResumed?.call();
                  }
                },
                backgroundColor: Colors.green,
                child: Icon(
                  !runControlState.hasRunStarted ? Icons.play_arrow : Icons.play_arrow,
                ),
              ),
            const SizedBox(width: 16),
            // Pause button (only show if running)
            if (runControlState.isRunning)
              FloatingActionButton(
                onPressed: () {
                  runControlNotifier.pauseRun();
                  locationNotifier.stopLocationStream();
                  onRunPaused?.call();
                },
                backgroundColor: Colors.orange,
                child: const Icon(Icons.pause),
              ),
            const SizedBox(width: 16),
            // Stop button
            if (runControlState.hasRunStarted && !runControlState.hasRunEnded)
              FloatingActionButton(
                onPressed: () {
                  final statistics = locationNotifier.stopRun();
                  runControlNotifier.stopRun(statistics);
                  onRunStopped?.call();
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
              ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(bool isRunning, bool isPaused, bool hasEnded) {
    if (hasEnded) return 'Run Finished';
    if (isRunning) return 'Run Active';
    if (isPaused) return 'Run Paused';
    return 'Ready to Start';
  }

  Color _getStatusColor(bool isRunning, bool isPaused) {
    if (isRunning) return Colors.green;
    if (isPaused) return Colors.orange;
    return Colors.grey;
  }
}
