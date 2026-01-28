import 'package:reelspark/ui/editor/editor.dart';

/// Control button widget with proper gesture handling (CapCut style)
///
/// Uses Listener for lower-level touch handling to avoid conflicts
/// with parent GestureDetector
class ControlButton extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Optional color override
  final Color? backgroundColor;

  /// Optional icon color override
  final Color? iconColor;

  const ControlButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerUp: (event) => onTap?.call(),
      child: Container(
        // Larger touch area (56x56) for accessibility
        width: 56,
        height: 56,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF1E1E1E),
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
          child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
        ),
      ),
    );
  }
}


