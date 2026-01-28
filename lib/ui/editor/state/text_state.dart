import 'package:reelspark/ui/editor/editor.dart';

/// Lightweight state class for text clips management
/// Holds list of text clips and selected clip reference
///
/// Pass this state object down via constructors
/// DO NOT use Provider/Riverpod yet
class TextState {
  /// List of all text clips on timeline
  List<TextClip> textClips;

  /// Currently selected text clip for editing
  TextClip? selectedTextClip;

  TextState({
    List<TextClip>? textClips,
    this.selectedTextClip,
  }) : textClips = textClips ?? [];

  /// Check if any text clip exists
  bool get hasTextClips => textClips.isNotEmpty;

  /// Get text clip by ID
  TextClip? getClipById(String id) {
    try {
      return textClips.firstWhere((clip) => clip.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new text clip
  void addClip(TextClip clip) {
    textClips.add(clip);
    selectedTextClip = clip;
  }

  /// Remove a text clip
  void removeClip(TextClip clip) {
    textClips.remove(clip);
    if (selectedTextClip?.id == clip.id) {
      selectedTextClip = null;
    }
  }

  /// Select a text clip
  void selectClip(TextClip? clip) {
    selectedTextClip = clip;
  }

  /// Deselect current clip
  void deselectClip() {
    selectedTextClip = null;
  }

  /// Get visible text clips at a specific time
  List<TextClip> getVisibleClipsAt(double time) {
    return textClips.where((clip) => clip.isVisibleAt(time)).toList();
  }

  /// Create a copy with modified values
  TextState copyWith({
    List<TextClip>? textClips,
    TextClip? selectedTextClip,
    bool clearSelection = false,
  }) {
    return TextState(
      textClips: textClips ?? List.from(this.textClips),
      selectedTextClip: clearSelection ? null : (selectedTextClip ?? this.selectedTextClip),
    );
  }
}
