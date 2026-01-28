// models/text_clip.dart
import 'dart:ui';

class TextClip {
  String id;
  String text;

  double startTime; // seconds on timeline
  double endTime;

  Offset position;
  double fontSize;
  double rotation;
  Color color;
  String fontFamily;
  double opacity;

  TextClip({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.position,
    required this.fontSize,
    required this.rotation,
    required this.color,
    required this.fontFamily,
    required this.opacity,
  });

  double get duration => endTime - startTime;

  bool isVisibleAt(double time) {
    return time >= startTime && time <= endTime;
  }

  TextClip copy() => TextClip(
    id: id,
    text: text,
    startTime: startTime,
    endTime: endTime,
    position: position,
    fontSize: fontSize,
    rotation: rotation,
    color: color,
    fontFamily: fontFamily,
    opacity: opacity,
  );

}
