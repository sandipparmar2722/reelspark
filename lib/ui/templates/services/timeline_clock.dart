import 'package:flutter/foundation.dart';

/// Single deterministic time source for template preview + render + GIF.
///
/// Rules:
/// - Time advances ONLY in fixed increments of (1 / fps).
/// - Frame index is derived from time: frameIndex = (timeSeconds * fps).floor().
/// - Callers are responsible for calling [step] explicitly.
/// - No wall-clock time is stored here.
class TimelineClock extends ChangeNotifier {
  final int fps;

  /// Total duration in seconds for one loop of the timeline.
  ///
  /// This is used for clamping/seeking and optional looping.
  final double totalDurationSeconds;

  /// Whether the clock loops back to 0 when it reaches [totalDurationSeconds].
  final bool loop;

  double _timeSeconds;
  int _frameIndex;

  TimelineClock({
    this.fps = 30,
    required this.totalDurationSeconds,
    this.loop = true,
    double initialTimeSeconds = 0.0,
  })  : assert(fps > 0),
        assert(totalDurationSeconds > 0),
        _timeSeconds = initialTimeSeconds.clamp(0.0, totalDurationSeconds),
        _frameIndex = (initialTimeSeconds.clamp(0.0, totalDurationSeconds) * fps).floor();

  double get timeSeconds => _timeSeconds;

  int get frameIndex => _frameIndex;

  double get frameDurationSeconds => 1.0 / fps;

  /// The exact number of frames produced for one full loop.
  ///
  /// We use floor() so time is always in-range and deterministic.
  int get totalFrames => (totalDurationSeconds * fps).floor().clamp(1, 1 << 30);

  bool get isAtEnd => !loop && _timeSeconds >= totalDurationSeconds;

  /// Jumps to an absolute time.
  void seekSeconds(double t) {
    final clamped = t.clamp(0.0, totalDurationSeconds);
    _timeSeconds = clamped;
    _frameIndex = (_timeSeconds * fps).floor();
    notifyListeners();
  }

  void seekProgress(double p) {
    seekSeconds((p.clamp(0.0, 1.0)) * totalDurationSeconds);
  }

  /// Advances exactly one frame.
  ///
  /// Returns true if the clock advanced, false if it is stopped at the end
  /// (when loop=false).
  bool step([int frames = 1]) {
    if (frames <= 0) return true;
    if (isAtEnd) return false;

    final d = frameDurationSeconds * frames;
    var next = _timeSeconds + d;

    if (loop) {
      // Loop based on frame count to avoid accumulating floating error.
      // Convert to frame space, add frames, and mod.
      final nextFrame = (_frameIndex + frames) % totalFrames;
      _frameIndex = nextFrame;
      _timeSeconds = _frameIndex / fps;
      notifyListeners();
      return true;
    }

    // Non-looping: clamp.
    if (next >= totalDurationSeconds) {
      next = totalDurationSeconds;
    }

    _timeSeconds = next;
    _frameIndex = (_timeSeconds * fps).floor();
    notifyListeners();
    return true;
  }
}

