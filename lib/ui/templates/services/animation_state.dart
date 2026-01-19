import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/video_template.dart';
import 'timeline_controller.dart';

/// Pure-math animation utilities (NO Flutter implicit animations).
///
/// This file intentionally contains only deterministic calculations.
class AnimationState {
  final double timeSeconds;
  final int frameIndex;

  final TimelineFrameState timeline;

  const AnimationState({
    required this.timeSeconds,
    required this.frameIndex,
    required this.timeline,
  });

  factory AnimationState.from({
    required TimelineController timelineController,
    required double timeSeconds,
  }) {
    final st = timelineController.getFrameStateAt(timeSeconds);
    return AnimationState(
      timeSeconds: st.absoluteTime,
      frameIndex: st.frameIndex,
      timeline: st,
    );
  }

  /// Standard normalized progress helper.
  static double progress({required double elapsed, required double duration}) {
    if (duration <= 0) return 1.0;
    return (elapsed / duration).clamp(0.0, 1.0);
  }

  /// Deterministic easeInOut applied as pure math.
  ///
  /// We still use Flutter's curve transform, but NOT an animation widget/controller.
  static double easeInOut(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

  static double easeInOutCubic(double t) => Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

  static double lerp(double a, double b, double t) => lerpDouble(a, b, t) ?? a;

  /// Text animation state derived from template + time.
  static TextAnimationState text(
    TimelineController controller,
    TemplateText text,
    double timeSeconds,
  ) {
    return controller.getTextAnimationState(text, timeSeconds);
  }
}

