import 'dart:io';
import 'dart:ui'; // ✅ REQUIRED for ImageFilter
import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';
import 'package:reelspark/models/effect_clip.dart';
import 'text_layer.dart';
import 'image_layer.dart';

/// Main preview area widget
/// - Base image track
/// - Transition between images
/// - Effect overlay track (CapCut-style)
/// - Text overlay track
class PreviewArea extends StatelessWidget {
  /// Images
  final List<File> images;

  final double keyboardHeight;
  final bool isKeyboardOpen;

  /// Current preview index
  final int currentPreviewIndex;

  /// Current playback time
  final double currentPlayTime;

  /// Transitions between clips
  final List<ClipTransition?> transitions;

  /// Effect overlay clips
  final List<EffectClip> effectClips;

  /// Text clips
  final List<TextClip> textClips;

  /// Selected text clip
  final TextClip? selectedTextClip;

  /// Animations from EditorScreen
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> zoomAnimation;

  /// Callbacks
  final VoidCallback? onTapOutside;
  final Function(TextClip)? onTextClipSelect;
  final Function(TextClip, Offset)? onTextPositionChanged;
  final Function(TextClip, double)? onTextFontSizeChanged;
  final Function(TextClip, double)? onTextRotationChanged;
  final Function(TextClip)? onTextClipRemove;
  final Function(TextClip)? onTextClipEdit;

  const PreviewArea({
    super.key,
    required this.images,
    required this.currentPreviewIndex,
    required this.currentPlayTime,
    required this.transitions,
    required this.effectClips,
    required this.textClips,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.zoomAnimation,
    this.selectedTextClip,
    this.onTapOutside,
    this.onTextClipSelect,
    this.onTextPositionChanged,
    this.onTextFontSizeChanged,
    this.onTextRotationChanged,
    this.onTextClipRemove,
    this.onTextClipEdit,
    required this.keyboardHeight,
    required this.isKeyboardOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapOutside,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// IMAGE + TRANSITION + EFFECTS
                _buildEffectOverlay(
                  _buildImageWithTransition(),
                ),

                /// TEXT LAYER
                TextLayer(
                  textClips: textClips,
                  currentPlayTime: currentPlayTime,
                  selectedTextClip: selectedTextClip,
                  keyboardHeight: keyboardHeight,
                  isKeyboardOpen: isKeyboardOpen,
                  onTextClipSelect: onTextClipSelect,
                  onTextPositionChanged: onTextPositionChanged,
                  onTextFontSizeChanged: onTextFontSizeChanged,
                  onTextRotationChanged: onTextRotationChanged,
                  onTextClipRemove: onTextClipRemove,
                  onTextClipEdit: onTextClipEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE + TRANSITION (CAPCUT STYLE)
  // ============================================================

  Widget _buildImageWithTransition() {
    if (images.isEmpty) return const SizedBox.shrink();

    final index = currentPreviewIndex.clamp(0, images.length - 1);

    final imageWidget = ImageLayer(
      key: ValueKey('image_$index'),
      image: images[index],
    );

    // First clip → no transition
    if (index == 0) return imageWidget;

    final transitionIndex = index - 1;
    if (transitionIndex < 0 ||
        transitionIndex >= transitions.length ||
        transitions[transitionIndex] == null) {
      return imageWidget;
    }

    final ClipTransition? transition = transitions[transitionIndex];

// ✅ HARD CUT (CapCut "None")
    if (transition == null || transition.type == ClipTransitionType.none) {
      return imageWidget;
    }

    switch (transition.type) {
      case ClipTransitionType.fade:
        return FadeTransition(
          opacity: fadeAnimation,
          child: imageWidget,
        );

      case ClipTransitionType.slideLeft:
        return SlideTransition(
          position: slideAnimation,
          child: imageWidget,
        );

      case ClipTransitionType.slideRight:
        return SlideTransition(
          position: slideAnimation.drive(
            Tween(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ),
          ),
          child: imageWidget,
        );

      case ClipTransitionType.zoom:
        return ScaleTransition(
          scale: zoomAnimation,
          child: imageWidget,
        );

    // Safety fallback
      default:
        return imageWidget;
    }

  }

  // ============================================================
  // EFFECT OVERLAY (CAPCUT STYLE – FIXED)
  // ============================================================

  Widget _buildEffectOverlay(Widget child) {
    final activeEffects = effectClips.where(
          (e) =>
      currentPlayTime >= e.startTime &&
          currentPlayTime <= e.endTime,
    );

    Widget result = child;

    for (final effect in activeEffects) {
      switch (effect.type) {
        case EffectType.blur:
          result = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 6,
              sigmaY: 6,
            ),
            child: result,
          );
          break;

        case EffectType.lightLeak:
          result = Stack(
            fit: StackFit.expand,
            children: [
              result,
              Container(
                color: Colors.orange.withOpacity(0.18),
              ),
            ],
          );
          break;

        case EffectType.glitch:
          result = Transform.translate(
            offset: Offset(
              (DateTime.now().millisecond % 8) - 4,
              0,
            ),
            child: result,
          );
          break;

        case EffectType.filmGrain:
          result = Stack(
            fit: StackFit.expand,
            children: [
              result,
              Container(
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          );
          break;
      }
    }

    return result;
  }
}
