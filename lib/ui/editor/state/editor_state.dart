import 'package:reelspark/ui/editor/editor.dart';

/// Lightweight state class for editor playback
/// Holds current playback position and play state
///
/// Pass this state object down via constructors
/// DO NOT use Provider/Riverpod yet
class EditorState {
  /// Current playback position in seconds
  double currentPlayTime;

  /// Whether playback is active
  bool isPlaying;

  double videoDuration = 0.0; // seconds
  /// Current preview image index
  int currentPreviewIndex;

  /// Selected clip index in timeline
  int selectedIndex;

  EditorState({
    this.currentPlayTime = 0.0,
    this.isPlaying = false,
    this.currentPreviewIndex = 0,
    this.selectedIndex = 0,
  });

  /// Create a copy with modified values
  EditorState copyWith({
    double? currentPlayTime,
    bool? isPlaying,
    int? currentPreviewIndex,
    int? selectedIndex,
  }) {
    return EditorState(
      currentPlayTime: currentPlayTime ?? this.currentPlayTime,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPreviewIndex: currentPreviewIndex ?? this.currentPreviewIndex,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  /// Format current time as MM:SS
  String get formattedCurrentTime {
    final minutes = (currentPlayTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (currentPlayTime.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Set the total video duration
  void setVideoDuration(double duration) {
    videoDuration = duration;
  }
}
