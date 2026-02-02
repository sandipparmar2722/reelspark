import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

/// CapCut-style Transition Picker
///
/// - Tap to PREVIEW transition
/// - ✔ Apply to CONFIRM
/// - ✕ Close to CANCEL
class TransitionPicker extends StatelessWidget {
  final Function(ClipTransitionType) onPreview;
  final VoidCallback onApply;
  final VoidCallback onClose;
  final ClipTransitionType? selectedType;

  const TransitionPicker({
    super.key,
    required this.onPreview,
    required this.onApply,
    required this.onClose,
    this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text(
                  'Transitions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // ✔ APPLY
                GestureDetector(
                  onTap: selectedType != null ? onApply : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: selectedType != null ? 1.0 : 0.35,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedType != null
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedType != null
                              ? Colors.white
                              : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: selectedType != null
                            ? Colors.black
                            : Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ✕ CLOSE
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

          const SizedBox(height: 10),

          // ================= TRANSITION GRID =================
          Expanded(
            child: GridView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              children: ClipTransitionType.values.map((type) {
                return _TransitionCard(
                  label: type.name.toUpperCase(),
                  isSelected: selectedType == type,
                  onTap: () => onPreview(type),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= TRANSITION CARD =================
class _TransitionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransitionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3A3A3A)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
