/// Time utility functions for the editor
///
/// Provides formatting and calculation helpers for timeline operations
class TimeUtils {
  /// Format time in seconds to MM:SS
  static String formatTime(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Format time in seconds to MM:SS.ms
  static String formatTimeWithMs(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    final ms = ((seconds - seconds.toInt()) * 100).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs.$ms';
  }

  /// Calculate start time for a specific clip index
  static double calculateStartTimeForIndex(List<double> durations, int index) {
    double time = 0;
    for (int i = 0; i < index && i < durations.length; i++) {
      time += durations[i];
    }
    return time;
  }

  /// Calculate total duration from list of durations
  static double calculateTotalDuration(List<double> durations) {
    return durations.fold(0.0, (sum, d) => sum + d);
  }

  /// Find clip index at a specific time
  static int findClipIndexAtTime(List<double> durations, double time) {
    double t = 0;
    for (int i = 0; i < durations.length; i++) {
      t += durations[i];
      if (time < t) {
        return i;
      }
    }
    return durations.length - 1;
  }

  /// Calculate timeline offset in pixels for a given time
  static double calculateTimelineOffset({
    required double time,
    required double pixelsPerSecond,
    required double maxOffset,
  }) {
    return (time * pixelsPerSecond).clamp(0.0, maxOffset);
  }

  /// Convert pixel offset to time
  static double pixelsToTime(double pixels, double pixelsPerSecond) {
    return pixels / pixelsPerSecond;
  }

  /// Convert time to pixel offset
  static double timeToPixels(double time, double pixelsPerSecond) {
    return time * pixelsPerSecond;
  }
}

