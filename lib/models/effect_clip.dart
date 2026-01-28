enum EffectType {
  none,
  blur,
  lightLeak,
  glitch,
  filmGrain,
}

class EffectClip {
  final String id;
  EffectType type;
  double startTime;
  double endTime;

  EffectClip({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  double get duration => endTime - startTime;

  EffectClip copy() => EffectClip(
    id: id,
    type: type,
    startTime: startTime,
    endTime: endTime,
  );
}
