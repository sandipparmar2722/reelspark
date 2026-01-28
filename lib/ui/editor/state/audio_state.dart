import 'package:reelspark/ui/editor/editor.dart';

/// Lightweight state class for audio management
/// Holds audio clip and ready state
///
/// Pass this state object down via constructors
/// DO NOT use Provider/Riverpod yet
class AudioState {
  /// Audio clip with trim support (nullable - may have no audio)
  AudioClip? audioClip;

  /// Flag to track if audio is loaded and ready
  bool isReady;

  AudioState({
    this.audioClip,
    this.isReady = false,
  });

  /// Check if audio exists
  bool get hasAudio => audioClip != null;

  /// Get audio duration (0 if no audio)
  double get duration => audioClip?.duration ?? 0.0;

  /// Get audio file name
  String get fileName => audioClip?.fileName ?? '';

  /// Check if a timeline position is within audio clip's range
  bool containsTime(double timePosition) {
    return audioClip?.containsTime(timePosition) ?? false;
  }

  /// Get the audio seek position for a given timeline position
  Duration? getAudioSeekPosition(double timelinePosition) {
    return audioClip?.getAudioSeekPosition(timelinePosition);
  }

  /// Create a copy with modified values
  AudioState copyWith({
    AudioClip? audioClip,
    bool? isReady,
    bool clearAudio = false,
  }) {
    return AudioState(
      audioClip: clearAudio ? null : (audioClip ?? this.audioClip),
      isReady: isReady ?? this.isReady,
    );
  }
}


