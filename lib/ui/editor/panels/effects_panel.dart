import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

/// Effects panel widget (CapCut-style)
///
/// Features:
/// - Grid-style effect cards
/// - Tap to preview effect
/// - ✔ Apply button in header (next to ✕)
class EffectsPanel extends StatelessWidget {
  final Function(EffectType) onEffectPreview;
  final VoidCallback? onApply;
  final VoidCallback? onClose;
  final bool canApply;

  const EffectsPanel({
    super.key,
    required this.onEffectPreview,
    this.onApply,
    this.onClose,
    this.canApply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text(
                  'Effects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // ================= ✔ APPLY =================
                GestureDetector(
                  onTap: canApply ? onApply : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: canApply ? 1.0 : 0.35,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: canApply ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canApply
                              ? Colors.white
                              : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color:
                        canApply ? Colors.black : Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ================= ✕ CLOSE =================
                if (onClose != null)
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================= EFFECT GRID =================
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: EffectType.values.length,
              itemBuilder: (context, index) {
                final type = EffectType.values[index];
                return _EffectCard(
                  label: type.name.toUpperCase(),
                  icon: _iconForEffect(type),
                  onTap: () => onEffectPreview(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForEffect(EffectType type) {
    switch (type) {
      case EffectType.blur:
        return Icons.blur_on;
      case EffectType.glitch:
        return Icons.broken_image;
      case EffectType.lightLeak:
        return Icons.wb_sunny;
      default:
        return Icons.auto_awesome;
    }
  }
}

/// ================= EFFECT CARD =================
class _EffectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _EffectCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
