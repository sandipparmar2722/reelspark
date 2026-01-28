enum ClipTransitionType {
  none,
  fade,
  slideLeft,
  slideRight,
  zoom,
}

class ClipTransition {
  final ClipTransitionType type;
  final double duration; // seconds

  const ClipTransition({
    required this.type,
    required this.duration,
  });

  ClipTransition copyWith({
    ClipTransitionType? type,
    double? duration,
  }) {
    return ClipTransition(
      type: type ?? this.type,
      duration: duration ?? this.duration,
    );
  }
}
