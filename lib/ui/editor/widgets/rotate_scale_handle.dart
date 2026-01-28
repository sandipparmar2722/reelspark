import 'package:reelspark/ui/editor/editor.dart';


/// Rotate and scale handle widget (CapCut style)
///
/// Uses Listener for lower-level touch handling that won't be
/// blocked by parent GestureDetector
class RotateScaleHandle extends StatelessWidget {
  /// The text clip this handle controls
  final TextClip clip;

  /// Callback when rotation starts
  final Function(PointerDownEvent)? onRotateStart;

  /// Callback when rotation updates
  final Function(PointerMoveEvent)? onRotateUpdate;

  /// Callback when rotation ends
  final VoidCallback? onRotateEnd;

  const RotateScaleHandle({
    super.key,
    required this.clip,
    this.onRotateStart,
    this.onRotateUpdate,
    this.onRotateEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onRotateStart,
      onPointerMove: onRotateUpdate,
      onPointerUp: (_) => onRotateEnd?.call(),
      onPointerCancel: (_) => onRotateEnd?.call(),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: 36,
          height: 36,
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
          child: const Icon(Icons.rotate_right, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}


