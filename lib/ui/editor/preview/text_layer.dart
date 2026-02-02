import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

class TextLayer extends StatefulWidget {
  final List<TextClip> textClips;
  final double currentPlayTime;
  final TextClip? selectedTextClip;

  final Function(TextClip)? onTextClipSelect;
  final Function(TextClip, Offset)? onTextPositionChanged;
  final Function(TextClip, double)? onTextFontSizeChanged;
  final Function(TextClip, double)? onTextRotationChanged;
  final Function(TextClip)? onTextClipRemove;
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
  double _baseFontSize = 36;
  double _baseRotation = 0.0;
  bool _isRotating = false;
  bool _isResizing = false;

  double _rotateStartAngle = 0.0;
  double _rotateStartDistance = 0.0;
  double _rotateStartFontSize = 36;

  @override
  Widget build(BuildContext context) {
    final double keyboardOffset =
    widget.isKeyboardOpen ? widget.keyboardHeight * 0.15 : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final clip in widget.textClips)
          if (clip.isVisibleAt(widget.currentPlayTime))
            _buildTextClipWidget(clip, keyboardOffset),
      ],
    );
  }

  Widget _buildTextClipWidget(TextClip clip, double keyboardOffset) {
    final isSelected = widget.selectedTextClip?.id == clip.id;

    // 🔥 Measure text size (WITH padding)
    final textPainter = TextPainter(
      text: TextSpan(
        text: clip.text,
        style: TextStyle(
          fontSize: clip.fontSize,
          fontFamily: clip.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    const horizontalPadding = 8.0;
    const verticalPadding = 4.0;

    final textSize = Size(
      textPainter.width + horizontalPadding * 2,
      textPainter.height + verticalPadding * 2,
    );

    // 🔥 CENTER → TOP LEFT (NO selection offset!)
    final topLeft = Offset(
      clip.position.dx - textSize.width / 2,
      clip.position.dy - textSize.height / 2,
    );

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: Transform.rotate(
        angle: clip.rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ================= TEXT =================
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onTextClipSelect?.call(clip),
              onScaleStart: (_) {
                _baseFontSize = clip.fontSize;
                _baseRotation = clip.rotation;
              },
              onScaleUpdate: (details) {
                if (_isRotating || _isResizing) return;

                // MOVE (center-based)
                if ((details.scale - 1.0).abs() < 0.1) {
                  widget.onTextPositionChanged?.call(
                    clip,
                    clip.position + details.focalPointDelta,
                  );
                }

                // SCALE
                if ((details.scale - 1.0).abs() >= 0.05) {
                  final newSize = (_baseFontSize * details.scale)
                      .clamp(TextLayer.minFontSize, TextLayer.maxFontSize);
                  widget.onTextFontSizeChanged?.call(clip, newSize);
                }

                // ROTATE
                if (details.rotation.abs() > 0.01) {
                  widget.onTextRotationChanged?.call(
                    clip,
                    _baseRotation + details.rotation,
                  );
                }
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black26 : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border:
                  isSelected ? Border.all(color: Colors.white) : null,
                ),
                child: Text(
                  clip.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: clip.fontFamily,
                    fontSize: clip.fontSize,
                    fontWeight: FontWeight.w400,
                    color: clip.color.withOpacity(clip.opacity),
                    height: 1.2,
                  ),
                ),
              ),
            ),

            // ================= REMOVE BUTTON (Top Left) =================
            if (isSelected)
              Positioned(
                top: -14,
                left: -14,
                child: _buildRemoveButton(clip),
              ),

            // ================= ROTATE HANDLE (Top Right) =================
            if (isSelected)
              Positioned(
                top: -14,
                right: -14,
                child: _buildRotateHandle(clip),
              ),

            // ================= RESIZE HANDLE (Bottom Right) =================
            if (isSelected)
              Positioned(
                bottom: -14,
                right: -14,
                child: _buildResizeHandle(clip),
              ),
          ],
        ),
      ),
    );
  }

  /// Build remove button (top left) - tap to delete
  Widget _buildRemoveButton(TextClip clip) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.onTextClipRemove?.call(clip);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }

  /// Build rotate handle (top right) - smooth rotation
  Widget _buildRotateHandle(TextClip clip) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _isRotating = true;
            final center = clip.position;
            _rotateStartAngle = math.atan2(
              details.globalPosition.dy - center.dy,
              details.globalPosition.dx - center.dx,
            );
            _baseRotation = clip.rotation;
          },
          onPanUpdate: (details) {
            if (!_isRotating) return;
            final center = clip.position;
            final currentAngle = math.atan2(
              details.globalPosition.dy - center.dy,
              details.globalPosition.dx - center.dx,
            );
            final deltaAngle = currentAngle - _rotateStartAngle;
            widget.onTextRotationChanged?.call(clip, _baseRotation + deltaAngle);
          },
          onPanEnd: (_) => _isRotating = false,
          onPanCancel: () => _isRotating = false,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.rotate_right, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }

  /// Build resize handle (bottom right) - drag to scale
  Widget _buildResizeHandle(TextClip clip) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _isResizing = true;
            _rotateStartDistance = (details.globalPosition - clip.position).distance;
            _rotateStartFontSize = clip.fontSize;
          },
          onPanUpdate: (details) {
            if (!_isResizing) return;
            final currentDistance = (details.globalPosition - clip.position).distance;
            final scale = currentDistance / _rotateStartDistance;
            final newSize = (_rotateStartFontSize * scale)
                .clamp(TextLayer.minFontSize, TextLayer.maxFontSize);
            widget.onTextFontSizeChanged?.call(clip, newSize);
          },
          onPanEnd: (_) => _isResizing = false,
          onPanCancel: () => _isResizing = false,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.open_in_full, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }
}
