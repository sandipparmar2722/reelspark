import 'package:reelspark/ui/editor/editor.dart';

/// Available transition effects between slides.
enum TransitionType { fade, slide, zoom, none }

/// Lightweight state class for filter/transition management
/// Holds current transition type and filter settings
///
/// Pass this state object down via constructors
/// DO NOT use Provider/Riverpod yet
class FilterState {
  /// Current transition type
  TransitionType transitionType;

  FilterState({
    this.transitionType = TransitionType.fade,
  });

  /// Create a copy with modified values
  FilterState copyWith({
    TransitionType? transitionType,
  }) {
    return FilterState(
      transitionType: transitionType ?? this.transitionType,
    );
  }
}
