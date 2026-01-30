enum EffectType {
  blur,
  lightLeak,
  glitch,
  filmGrain,
}

class EffectClip {
  final String id;
  final EffectType type;

  double startTime; // 🔥 NOT final
  double endTime;   // 🔥 NOT final

  final bool isPreview;

  EffectClip({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.isPreview = false,
  });

  double get duration => endTime - startTime;

  /// ✅ Undo / Redo
  EffectClip copy() {
    return EffectClip(
      id: id,
      type: type,
      startTime: startTime,
      endTime: endTime,
      isPreview: isPreview,
    );
  }

  /// ✅ Preview → Confirm
  EffectClip copyWith({
    String? id,
    double? startTime,
    double? endTime,
    bool? isPreview,
  }) {
    return EffectClip(
      id: id ?? this.id,
      type: type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPreview: isPreview ?? this.isPreview,
    );
  }
}
