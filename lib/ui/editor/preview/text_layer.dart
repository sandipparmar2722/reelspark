import 'dart:math' as math;

import 'package:reelspark/ui/editor/editor.dart';

/// Text layer widget for the preview area
///
/// Displays all visible text clips with:
/// - Text rendering with styles
/// - Selection UI (border, control buttons)
/// - Drag to move, pinch to scale/rotate
/// - Uses isVisibleAt() for timeline-based visibility
class TextLayer extends StatefulWidget {
  /// List of all text clips
  final List<TextClip> textClips;

  /// Current playback time in seconds
  final double currentPlayTime;

  /// Currently selected text clip
  final TextClip? selectedTextClip;

  /// Callback when a text clip is selected
  final Function(TextClip)? onTextClipSelect;

  /// Callback when text clip position changes
  final Function(TextClip, Offset)? onTextPositionChanged;

  /// Callback when text clip font size changes
  final Function(TextClip, double)? onTextFontSizeChanged;

  /// Callback when text clip rotation changes
  final Function(TextClip, double)? onTextRotationChanged;

  /// Callback when text clip is removed
  final Function(TextClip)? onTextClipRemove;

  /// Callback when text clip edit is requested
  final Function(TextClip)? onTextClipEdit;

  static const double minFontSize = 12;
  static const double maxFontSize = 120;
  final double keyboardHeight;
  final bool isKeyboardOpen;


  const TextLayer({
    super.key,
    required this.textClips,
    required this.currentPlayTime,
    this.selectedTextClip,
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
  State<TextLayer> createState() => _TextLayerState();
}

class _TextLayerState extends State<TextLayer> {
  // Gesture state
  double _baseFontSize = 36;
  double _baseRotation = 0.0;
  bool _isRotating = false;
  double _rotateStartAngle = 0.0;
  double _rotateStartDistance = 0.0;
  double _rotateStartFontSize = 36;

  @override
  Widget build(BuildContext context) {
    // CapCut-style keyboard offset: text moves up to stay visible
    // This compensates for the preview's transform so text remains in correct position
    final double keyboardOffset =
        widget.isKeyboardOpen ? widget.keyboardHeight * 0.15 : 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final clip in widget.textClips)
          if (clip.isVisibleAt(widget.currentPlayTime))
            _buildTextClipWidget(clip, keyboardOffset),
      ],
    );
  }


  Widget  _buildTextClipWidget(TextClip clip, double keyboardOffset) {
    final isSelected = widget.selectedTextClip?.id == clip.id;

     return Positioned(
      left: clip.position.dx - (isSelected ? 30 : 0),
      top: clip.position.dy - keyboardOffset - (isSelected ? 30 : 0),
      child: Transform.rotate(
        angle: clip.rotation,
        child: Padding(
          padding: EdgeInsets.all(isSelected ? 30 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Text transform gestures
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTextClipSelect?.call(clip),
                onScaleStart: (_) {
                  _baseFontSize = clip.fontSize;
                  _baseRotation = clip.rotation;
                },
                onScaleUpdate: (details) {
                  if (_isRotating) return;

                  // MOVE - only if single finger drag (scale ~ 1.0)
                  if ((details.scale - 1.0).abs() < 0.1) {
                    final newPosition = clip.position + details.focalPointDelta;
                    widget.onTextPositionChanged?.call(clip, newPosition);
                  }

                  // SCALE - when pinching (scale changes)
                  if ((details.scale - 1.0).abs() >= 0.05) {
                    final newSize = (_baseFontSize * details.scale)
                        .clamp(TextLayer.minFontSize, TextLayer.maxFontSize);
                    widget.onTextFontSizeChanged?.call(clip, newSize);
                  }

                  // ROTATE - when rotating gesture detected
                  if (details.rotation.abs() > 0.01) {
                    final newRotation = _baseRotation + details.rotation;
                    widget.onTextRotationChanged?.call(clip, newRotation);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black26 : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected ? Border.all(color: Colors.white) : null,
                  ),
                  child: Text(
                    clip.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: clip.fontFamily,          // ✅ font now applies
                      fontSize: clip.fontSize,
                      fontWeight: FontWeight.normal,        // ✅ DO NOT force bold
                      color: clip.color.withOpacity(clip.opacity), // ✅ correct
                      height: 1.2,                          // ✨ modern look
                      letterSpacing: 0.3,                   // ✨ CapCut-style
                    ),
                  ),

                ),
              ),

              // Remove (X) button
              if (isSelected)
                Positioned(
                  top: -28,
                  left: -28,
                  child: ControlButton(
                    icon: Icons.close,
                    onTap: () => widget.onTextClipRemove?.call(clip),
                  ),
                ),

              // Edit (✏️) button
              if (isSelected)
                Positioned(
                  top: -28,
                  right: -28,
                  child: ControlButton(
                    icon: Icons.edit,
                    onTap: () => widget.onTextClipEdit?.call(clip),
                  ),
                ),

              // Rotate + Scale handle
              if (isSelected)
                Positioned(
                  bottom: -28,
                  right: -28,
                  child: RotateScaleHandle(
                    clip: clip,
                    onRotateStart: (event) {
                      _isRotating = true;
                      final center = clip.position +
                          Offset(clip.fontSize / 2, clip.fontSize / 2);
                      _rotateStartAngle = math.atan2(
                        event.position.dy - center.dy,
                        event.position.dx - center.dx,
                      );
                      _rotateStartDistance = (event.position - center).distance;
                      _rotateStartFontSize = clip.fontSize;
                    },
                    onRotateUpdate: (event) {
                      if (!_isRotating) return;

                      final center = clip.position +
                          Offset(clip.fontSize / 2, clip.fontSize / 2);
                      final angle = math.atan2(
                        event.position.dy - center.dy,
                        event.position.dx - center.dx,
                      );
                      final distance = (event.position - center).distance;

                      // Rotation
                      final newRotation = clip.rotation + angle - _rotateStartAngle;
                      widget.onTextRotationChanged?.call(clip, newRotation);
                      _rotateStartAngle = angle;

                      // Scale
                      final scale = distance / _rotateStartDistance;
                      final newSize = (_rotateStartFontSize * scale)
                          .clamp(TextLayer.minFontSize, TextLayer.maxFontSize);
                      widget.onTextFontSizeChanged?.call(clip, newSize);
                    },
                    onRotateEnd: () => _isRotating = false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

