/// Model for audio clip with trim support
///
/// This model allows:
/// - Trimming audio start/end
/// - Positioning audio on timeline
/// - Future: multiple clips, drag, split, mute
class AudioClip {
  /// Path to the audio file
  final String path;

  /// Display name of the audio file
  final String fileName;

  /// Original full duration of the audio file (in seconds)
  final double originalDuration;

  /// Where this audio clip starts on the timeline (in seconds)
  /// Future: allows dragging audio horizontally
  double startTime;

  /// Trim start offset inside the audio file (in seconds)
  /// 0 = start from beginning
  double trimStart;

  /// Trim end offset inside the audio file (in seconds)
  /// originalDuration = use full audio
  double trimEnd;

  AudioClip({
    required this.path,
    required this.fileName,
    required this.originalDuration,
    this.startTime = 0.0,
    double? trimStart,
    double? trimEnd,
  })  : trimStart = trimStart ?? 0.0,
        trimEnd = trimEnd ?? originalDuration;

  /// The playable duration after trimming
  double get duration => trimEnd - trimStart;

  /// Width in pixels based on pixelsPerSecond
  double getWidth(double pixelsPerSecond) => duration * pixelsPerSecond;

  /// Timeline end position
  double get endTime => startTime + duration;

  /// Check if a timeline position is within this clip's range
  bool containsTime(double timePosition) {
    return timePosition >= startTime && timePosition < endTime;
  }

  /// Get the audio seek position for a given timeline position
  /// Returns null if timeline position is outside this clip
  Duration? getAudioSeekPosition(double timelinePosition) {
    if (!containsTime(timelinePosition)) return null;

    final offsetInClip = timelinePosition - startTime;
    final audioPosition = trimStart + offsetInClip;
    return Duration(milliseconds: (audioPosition * 1000).toInt());
  }

  /// Create a copy with modified values
  AudioClip copyWith({
    String? path,
    String? fileName,
    double? originalDuration,
    double? startTime,
    double? trimStart,
    double? trimEnd,
  }) {
    return AudioClip(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      originalDuration: originalDuration ?? this.originalDuration,
      startTime: startTime ?? this.startTime,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
    );
  }

  /// Minimum allowed duration (in seconds)
  static const double minDuration = 0.5;

  /// Clamp trim values to valid range
  void clampTrimValues() {
    trimStart = trimStart.clamp(0.0, originalDuration - minDuration);
    trimEnd = trimEnd.clamp(trimStart + minDuration, originalDuration);
  }

  @override
  String toString() {
    return 'AudioClip(path: $path, startTime: $startTime, '
        'trimStart: $trimStart, trimEnd: $trimEnd, duration: $duration)';
  }
}

