import 'package:reelspark/ui/editor/editor.dart';

/// Effects/Transitions panel widget
///
/// Contains:
/// - Transition type selector (fade, slide, zoom)
class EffectsPanel extends StatelessWidget {
  /// Current transition type
  final TransitionType transitionType;

  /// Callback when transition type changes
  final Function(TransitionType)? onTransitionChanged;

  /// Callback when panel is closed
  final VoidCallback? onClose;

  const EffectsPanel({
    super.key,
    required this.transitionType,
    this.onTransitionChanged,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Transitions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Transition Options
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildTransitionOption(
                icon: Icons.blur_on,
                label: 'Fade',
                type: TransitionType.fade,
              ),
              const SizedBox(width: 10),
              _buildTransitionOption(
                icon: Icons.swap_horiz,
                label: 'Slide',
                type: TransitionType.slide,
              ),
              const SizedBox(width: 10),
              _buildTransitionOption(
                icon: Icons.zoom_in,
                label: 'Zoom',
                type: TransitionType.zoom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionOption({
    required IconData icon,
    required String label,
    required TransitionType type,
  }) {
    final isSelected = transitionType == type;

    return GestureDetector(
      onTap: () => onTransitionChanged?.call(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white12 : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white38 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


