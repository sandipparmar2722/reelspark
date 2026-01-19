import '../templates.dart';

/// Data model for a video template.
///
/// Supports:
/// - Offline + online templates
/// - Animated text (lyrics)
/// - Sticker overlays (confetti / hearts)
/// - BPM based beat-sync motion
class VideoTemplate {
  final String id;
  final String title;

  /// Asset or local path to preview video
  final String previewVideo;

  /// Asset or local path to background music
  final String music;

  /// Base number of required photo slots
  final int slots;

  /// Default duration per image in seconds
  final int durationPerImage;

  /// Default visual effect
  final String effect;

  /// Default transition
  final String transition;

  /// Optional per-slot timeline
  final List<TemplateStep> timeline;

  /// Category (Home tabs)
  final String category;

  /// 🔥 NEW: Music BPM for beat-sync animation
  final int? bpm;

  /// 🔥 NEW: Animated texts (lyrics / wishes)
  final List<TemplateText> texts;

  /// 🔥 NEW: Sticker overlays (confetti / hearts)
  final List<TemplateSticker> stickers;

  const VideoTemplate({
    required this.id,
    required this.title,
    required this.previewVideo,
    required this.music,
    required this.slots,
    required this.durationPerImage,
    this.effect = 'default',
    this.transition = 'cut',
    this.timeline = const [],
    this.category = 'For you',
    this.bpm,
    this.texts = const [],
    this.stickers = const [],
  });

  /// Effective number of slots
  int get resolvedSlots => timeline.isNotEmpty ? timeline.length : slots;

  int durationForIndex(int index) {
    if (timeline.isEmpty) return durationPerImage;
    return timeline[index % timeline.length].duration;
  }

  String effectForIndex(int index) {
    if (timeline.isEmpty) return effect;
    return timeline[index % timeline.length].effect;
  }

  String transitionForIndex(int index) {
    if (timeline.isEmpty) return transition;
    return timeline[index % timeline.length].transition;
  }

  String motionForIndex(int index) {
    if (timeline.isEmpty) return 'kenburns';
    return timeline[index % timeline.length].motion;
  }

  /// ✅ SAFE JSON PARSING (offline + online)
  factory VideoTemplate.fromJson(Map<String, dynamic> json) {
    final timelineJson = json['timeline'];
    final timeline = <TemplateStep>[];

    if (timelineJson is List) {
      for (final step in timelineJson) {
        if (step is Map<String, dynamic>) {
          timeline.add(TemplateStep.fromJson(step));
        }
      }
    }

    final textsJson = json['texts'];
    final stickersJson = json['stickers'];

    return VideoTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      previewVideo: json['previewVideo'] as String,
      music: json['music'] as String,
      slots: (json['slots'] as num).toInt(),
      durationPerImage: (json['durationPerImage'] as num).toInt(),
      effect: (json['effect'] as String?) ?? 'default',
      transition: (json['transition'] as String?) ?? 'cut',
      category: (json['category'] as String?) ?? 'For you',
      bpm: (json['bpm'] as num?)?.toInt(),

      texts: textsJson is List
          ? textsJson
          .whereType<Map<String, dynamic>>()
          .map(TemplateText.fromJson)
          .toList()
          : const [],

      stickers: stickersJson is List
          ? stickersJson
          .whereType<Map<String, dynamic>>()
          .map(TemplateSticker.fromJson)
          .toList()
          : const [],

      timeline: timeline,
    );
  }
}

/// One per-slot step in a template timeline
class TemplateStep {
  final int duration;
  final String effect;
  final String transition;
  final String motion;

  const TemplateStep({
    required this.duration,
    required this.effect,
    required this.transition,
    this.motion = 'kenburns',
  });

  factory TemplateStep.fromJson(Map<String, dynamic> json) {
    return TemplateStep(
      duration: ((json['duration'] as num?) ?? 2).toInt(),
      effect: (json['effect'] as String?) ?? 'default',
      transition: (json['transition'] as String?) ?? 'fade',
      motion: (json['motion'] as String?) ?? 'kenburns',
    );
  }
}

/// 🔤 Animated text (lyrics / wishes)
class TemplateText {
  final String text;
  final int start;
  final int end;
  final String animation;
  final String position;
  final String style;

  const TemplateText({
    required this.text,
    required this.start,
    required this.end,
    required this.animation,
    required this.position,
    required this.style,
  });

  factory TemplateText.fromJson(Map<String, dynamic> json) {
    return TemplateText(
      text: json['text'] ?? '',
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 1,
      animation: json['animation'] ?? 'fade',
      position: json['position'] ?? 'center',
      style: json['style'] ?? 'bold_white',
    );
  }
}

/// 🎉 Sticker overlay (confetti / hearts)
class TemplateSticker {
  final String asset;
  final int start;
  final int end;
  final String position;

  const TemplateSticker({
    required this.asset,
    required this.start,
    required this.end,
    required this.position,
  });

  factory TemplateSticker.fromJson(Map<String, dynamic> json) {
    return TemplateSticker(
      asset: json['asset'] ?? '',
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 5,
      position: json['position'] ?? 'full',
    );
  }
}
