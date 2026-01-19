import '../templates.dart';

import 'package:flutter/material.dart';

import '../services/animation_state.dart';
import '../services/timeline_controller.dart';

/// Motion transform used by template live preview.
///
/// ABSOLUTE RULE: This widget does NOT animate itself.
/// It renders a single frame based on [progress] (0..1) provided by the
/// frame-locked preview clock.
class TemplateMotion extends StatelessWidget {
  final String motion;
  final double progress;
  final Widget child;

  const TemplateMotion({
    super.key,
    required this.motion,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Use the same motion math as render (TimelineController.getMotionTransform)
    // but DO NOT instantiate a dummy TimelineController each frame.
    // The motion presets are deterministic, so we can just compute via a small helper.
    final transform = _motionTransform(motion, progress);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final dx = transform.offsetX * w;
        final dy = transform.offsetY * h;

        return ClipRect(
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: transform.scale,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Local deterministic motion helper to avoid allocating controllers.
  static MotionTransform _motionTransform(String motion, double t) {
    final eased = AnimationState.easeInOut(t);

    double beginScale = 1.0;
    double endScale = 1.0;
    double beginOffsetX = 0.0;
    double endOffsetX = 0.0;
    double beginOffsetY = 0.0;
    double endOffsetY = 0.0;

    switch (motion) {
      case 'zoom_in':
        beginScale = 1.0;
        endScale = 1.12;
        break;
      case 'zoom_out':
        beginScale = 1.12;
        endScale = 1.0;
        break;
      case 'pan_left':
        beginScale = 1.14;
        endScale = 1.14;
        beginOffsetX = 0.06;
        endOffsetX = -0.06;
        break;
      case 'pan_right':
        beginScale = 1.14;
        endScale = 1.14;
        beginOffsetX = -0.06;
        endOffsetX = 0.06;
        break;
      case 'pan_up':
        beginScale = 1.14;
        endScale = 1.14;
        beginOffsetY = 0.06;
        endOffsetY = -0.06;
        break;
      case 'pan_down':
        beginScale = 1.14;
        endScale = 1.14;
        beginOffsetY = -0.06;
        endOffsetY = 0.06;
        break;
      case 'none':
        break;
      case 'kenburns':
      default:
        beginScale = 1.0;
        endScale = 1.06;
        beginOffsetX = -0.02;
        endOffsetX = 0.02;
        beginOffsetY = 0.01;
        endOffsetY = -0.01;
        break;
    }

    return MotionTransform(
      scale: AnimationState.lerp(beginScale, endScale, eased),
      offsetX: AnimationState.lerp(beginOffsetX, endOffsetX, eased),
      offsetY: AnimationState.lerp(beginOffsetY, endOffsetY, eased),
    );
  }
}

/// Deterministic dual-layer transition renderer.
///
/// ABSOLUTE RULE: This widget does NOT animate.
/// It renders exactly one frame based on [t] (0..1) provided by the clock.
class DualTransitionFrame extends StatelessWidget {
  final String transition;
  final double t;
  final Widget fromChild;
  final Widget toChild;

  const DualTransitionFrame({
    super.key,
    required this.transition,
    required this.t,
    required this.fromChild,
    required this.toChild,
  });

  @override
  Widget build(BuildContext context) {
    final tt = t.clamp(0.0, 1.0);
    if (tt <= 0.0) return fromChild;
    if (tt >= 1.0) return toChild;

    final curved = AnimationState.easeInOutCubic(tt);

    switch (transition) {
      case 'fade':
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 1.0 - curved, child: fromChild),
            Opacity(opacity: curved, child: toChild),
          ],
        );

      case 'slide_left':
        return Stack(
          fit: StackFit.expand,
          children: [
            FractionalTranslation(
              translation: Offset(-curved, 0),
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            FractionalTranslation(
              translation: Offset(1.0 - curved, 0),
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'slide_up':
        return Stack(
          fit: StackFit.expand,
          children: [
            FractionalTranslation(
              translation: Offset(0, -curved),
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            FractionalTranslation(
              translation: Offset(0, 1.0 - curved),
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'wipe':
        return Stack(
          fit: StackFit.expand,
          children: [
            fromChild,
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: curved,
                child: toChild,
              ),
            ),
          ],
        );

      case 'zoom':
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: AnimationState.lerp(1.0, 1.25, curved),
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            Transform.scale(
              scale: AnimationState.lerp(0.8, 1.0, curved),
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'cut':
      default:
        return fromChild; // hold until end
    }
  }
}
