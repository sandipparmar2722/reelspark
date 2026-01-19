import 'dart:async';

import 'package:flutter/material.dart';

import '../models/video_template.dart';

/// Unified timeline controller for both preview and render.
///
/// This ensures frame-perfect timing synchronization between:
/// - Live preview (real-time playback)
/// - Offscreen render (frame-by-frame export)
///
/// KEY DESIGN PRINCIPLES:
/// 1. Single source of truth for all timing calculations
/// 2. FPS-locked frame indexing: frameIndex = (timeSeconds * fps).floor()
/// 3. Time-based interpolation, not frame-based
/// 4. Deterministic: same time input = same visual output
class TimelineController {
  /// Target FPS for both preview and render (locked to 30fps).
  static const int fps = 30;

  /// Transition duration in seconds (520ms = 0.52s).
  static const double transitionDuration = 0.52;

  /// Frame duration in seconds.
  static double get frameDuration => 1.0 / fps;

  /// Template being controlled.
  final VideoTemplate template;

  /// Pre-computed timeline steps.
  final List<TemplateStep> steps;

  /// Pre-computed absolute start time for each step (seconds).
  final List<double> stepStartTimes;

  /// Total duration in seconds.
  final double totalDuration;

  /// Total frame count.
  final int totalFrames;

  TimelineController._({
    required this.template,
    required this.steps,
    required this.stepStartTimes,
    required this.totalDuration,
    required this.totalFrames,
  });

  /// Creates a timeline controller from a template.
  factory TimelineController.fromTemplate(VideoTemplate template) {
    final steps = _computeSteps(template);
    final (startTimes, total) = _computeStepStartTimes(steps);
    final frames = (total * fps).round().clamp(1, 1 << 30);

    return TimelineController._(
      template: template,
      steps: steps,
      stepStartTimes: startTimes,
      totalDuration: total,
      totalFrames: frames,
    );
  }

  /// Generates beat-synced timeline based on template BPM.
  ///
  /// If the template already has a timeline, it is returned as-is.
  /// Otherwise, creates a new timeline with durations based on BPM.
  static List<TemplateStep> _computeSteps(VideoTemplate t) {
    if (t.timeline.isNotEmpty) return t.timeline;

    final bpm = t.bpm ?? 100;
    final sec = (60 / bpm * 2).clamp(1, 2).round();

    return List.generate(
      t.slots,
      (i) => TemplateStep(
        duration: sec,
        effect: t.effect,
        transition: i.isEven ? 'cut' : 'fade',
        motion: _beatMotion(i),
      ),
    );
  }

  /// Returns a motion pattern that cycles through different movements.
  static String _beatMotion(int i) {
    const motions = [
      'zoom_in',
      'zoom_out',
      'pan_left',
      'pan_right',
      'kenburns',
    ];
    return motions[i % motions.length];
  }

  /// Computes absolute start times for each step.
  static (List<double>, double) _computeStepStartTimes(List<TemplateStep> steps) {
    final startTimes = <double>[];
    var acc = 0.0;
    for (final s in steps) {
      startTimes.add(acc);
      acc += s.duration.toDouble();
    }
    return (startTimes, acc);
  }

  /// Gets the frame state at a specific time in seconds.
  ///
  /// This is the CORE method that both preview and render must use
  /// to ensure identical visual output.
  TimelineFrameState getFrameStateAt(double timeSeconds) {
    timeSeconds = timeSeconds.clamp(0.0, totalDuration);

    // Find which step we're in
    int stepIndex = 0;
    for (int i = steps.length - 1; i >= 0; i--) {
      if (timeSeconds >= stepStartTimes[i]) {
        stepIndex = i;
        break;
      }
    }

    final step = steps[stepIndex];
    final stepStartTime = stepStartTimes[stepIndex];
    final stepDuration = step.duration.toDouble();

    // Time within this step
    final timeInStep = (timeSeconds - stepStartTime).clamp(0.0, stepDuration);

    // Motion progress: 0.0 to 1.0 over the full step duration
    final motionProgress = stepDuration > 0 ? (timeInStep / stepDuration).clamp(0.0, 1.0) : 1.0;

    // Transition calculation: transition happens at the END of each step
    // Transition starts at (stepDuration - transitionDuration) and ends at stepDuration
    final transitionStart = (stepDuration - transitionDuration).clamp(0.0, stepDuration);
    final isInTransition = timeInStep >= transitionStart && transitionDuration > 0;

    double transitionProgress = 0.0;
    if (isInTransition) {
      final transitionTime = timeInStep - transitionStart;
      final actualTransitionDuration = (stepDuration - transitionStart).clamp(0.001, transitionDuration);
      transitionProgress = (transitionTime / actualTransitionDuration).clamp(0.0, 1.0);
    }

    // Next step info for transitions
    final nextStepIndex = (stepIndex + 1) % steps.length;
    final nextStep = steps[nextStepIndex];

    return TimelineFrameState(
      absoluteTime: timeSeconds,
      frameIndex: (timeSeconds * fps).floor(),
      stepIndex: stepIndex,
      nextStepIndex: nextStepIndex,
      step: step,
      nextStep: nextStep,
      timeInStep: timeInStep,
      stepDuration: stepDuration,
      motionProgress: motionProgress,
      isInTransition: isInTransition,
      transitionProgress: transitionProgress,
      transitionType: step.transition,
    );
  }

  /// Gets the frame state at a specific frame index.
  TimelineFrameState getFrameStateAtFrame(int frameIndex) {
    final timeSeconds = frameIndex * frameDuration;
    return getFrameStateAt(timeSeconds);
  }

  /// Gets motion transform values at a specific progress (0.0 to 1.0).
  ///
  /// Returns (scale, offsetX, offsetY) normalized to frame size.
  MotionTransform getMotionTransform(String motion, double progress) {
    progress = Curves.easeInOut.transform(progress.clamp(0.0, 1.0));

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
        // No motion
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
      scale: beginScale + (endScale - beginScale) * progress,
      offsetX: beginOffsetX + (endOffsetX - beginOffsetX) * progress,
      offsetY: beginOffsetY + (endOffsetY - beginOffsetY) * progress,
    );
  }

  /// Gets text animation values at a specific time.
  TextAnimationState getTextAnimationState(
    TemplateText text,
    double timeSeconds,
  ) {
    final isActive = timeSeconds >= text.start && timeSeconds <= text.end;
    if (!isActive) {
      return const TextAnimationState(isActive: false, opacity: 0, scale: 1);
    }

    final span = (text.end - text.start).clamp(1, 1 << 30).toDouble();
    final localT = ((timeSeconds - text.start) / span).clamp(0.0, 1.0);

    switch (text.animation) {
      case 'beat_pop':
        // Consistent pulse at 2Hz regardless of playback
        final pulse = ((timeSeconds * 2) % 1.0);
        final scale = 1.0 + (pulse < 0.5 ? pulse * 0.15 : (1.0 - pulse) * 0.15);
        return TextAnimationState(isActive: true, opacity: 1.0, scale: scale);

      case 'zoom_in':
        final scale = 0.5 + (localT * 0.5);
        return TextAnimationState(isActive: true, opacity: localT, scale: scale);

      case 'fade':
        return TextAnimationState(isActive: true, opacity: localT, scale: 1.0);

      default:
        return const TextAnimationState(isActive: true, opacity: 1.0, scale: 1.0);
    }
  }

  /// Checks if a sticker is active at a specific time.
  bool isStickerActive(TemplateSticker sticker, double timeSeconds) {
    return timeSeconds >= sticker.start && timeSeconds <= sticker.end;
  }

  /// Gets the step duration in seconds at a specific step index.
  double getStepDuration(int stepIndex) {
    return steps[stepIndex % steps.length].duration.toDouble();
  }

  /// Gets the step start time in seconds.
  double getStepStartTime(int stepIndex) {
    return stepStartTimes[stepIndex % steps.length];
  }
}

/// Immutable state representing a single frame in the timeline.
class TimelineFrameState {
  /// Absolute time in seconds from video start.
  final double absoluteTime;

  /// Frame index (0-based).
  final int frameIndex;

  /// Current step index.
  final int stepIndex;

  /// Next step index (for transitions).
  final int nextStepIndex;

  /// Current step.
  final TemplateStep step;

  /// Next step.
  final TemplateStep nextStep;

  /// Time within the current step (seconds).
  final double timeInStep;

  /// Total duration of the current step (seconds).
  final double stepDuration;

  /// Motion progress (0.0 to 1.0) over the full step.
  final double motionProgress;

  /// Whether we're currently in a transition.
  final bool isInTransition;

  /// Transition progress (0.0 to 1.0) during transition.
  final double transitionProgress;

  /// Type of transition ('fade', 'slide_left', etc.).
  final String transitionType;

  const TimelineFrameState({
    required this.absoluteTime,
    required this.frameIndex,
    required this.stepIndex,
    required this.nextStepIndex,
    required this.step,
    required this.nextStep,
    required this.timeInStep,
    required this.stepDuration,
    required this.motionProgress,
    required this.isInTransition,
    required this.transitionProgress,
    required this.transitionType,
  });
}

/// Motion transform values.
class MotionTransform {
  final double scale;
  final double offsetX; // Normalized to frame width
  final double offsetY; // Normalized to frame height

  const MotionTransform({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

/// Text animation state.
class TextAnimationState {
  final bool isActive;
  final double opacity;
  final double scale;

  const TextAnimationState({
    required this.isActive,
    required this.opacity,
    required this.scale,
  });
}

