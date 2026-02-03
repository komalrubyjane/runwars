import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/gps_tracking_model.dart';
import 'state/run_control_state.dart';

final runControlViewModelProvider =
    StateNotifierProvider<RunControlViewModel, RunControlState>(
  (ref) => RunControlViewModel(),
);

/// View model for managing run start/stop controls and run state
class RunControlViewModel extends StateNotifier<RunControlState> {
  RunControlViewModel() : super(RunControlState.initial());

  /// Starts a new run
  void startRun() {
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      runStartTime: DateTime.now(),
      runEndTime: null,
      hasRunEnded: false,
    );
  }

  /// Pauses the current run
  void pauseRun() {
    if (state.isRunning) {
      state = state.copyWith(
        isRunning: false,
        isPaused: true,
      );
    }
  }

  /// Resumes a paused run
  void resumeRun() {
    if (state.isPaused && !state.hasRunEnded) {
      state = state.copyWith(
        isRunning: true,
        isPaused: false,
      );
    }
  }

  /// Stops the current run and finalizes it
  void stopRun(RunStatistics statistics) {
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      runEndTime: DateTime.now(),
      hasRunEnded: true,
      finalStatistics: statistics,
    );
  }

  /// Resets the run state
  void resetRun() {
    state = RunControlState.initial();
  }

  /// Gets the current run status
  RunStatus getRunStatus() {
    if (!state.hasRunStarted) return RunStatus.notStarted;
    if (state.hasRunEnded) return RunStatus.finished;
    if (state.isRunning) return RunStatus.running;
    if (state.isPaused) return RunStatus.paused;
    return RunStatus.notStarted;
  }

  /// Gets elapsed time in seconds
  int getElapsedSeconds() {
    if (state.runStartTime == null) return 0;
    
    final now = state.runEndTime ?? DateTime.now();
    final elapsed = now.difference(state.runStartTime!);
    
    return elapsed.inSeconds;
  }
}

/// Enum representing different run statuses
enum RunStatus {
  notStarted,
  running,
  paused,
  finished,
}
