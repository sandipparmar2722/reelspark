import 'package:flutter/material.dart';

// ============================================================================
// EDITOR TOOL ENUM
// ============================================================================
/// Available tools in the editor bottom toolbar.
/// These map to specific editor actions (music, text, effects/transitions).
enum EditorTool {
  audio,
  text,
  effects,
}

// ============================================================================
// CAPCUT-STYLE BOTTOM TOOLBAR
// ============================================================================
/// A CapCut-inspired bottom toolbar with icon + label buttons.
///
/// Features:
/// - Fixed at bottom of screen
/// - 3 tools: Audio, Text, Effects
/// - Active tool gets highlighted with underline indicator
/// - Smooth animations on selection
class EditorBottomBar extends StatelessWidget {
  // --- Callbacks (actions) ---
  final VoidCallback onAudio;
  final VoidCallback onText;
  final VoidCallback onEffects;

  // --- State ---
  final EditorTool? activeTool;

  const EditorBottomBar({
    super.key,
    required this.onAudio,
    required this.onText,
    required this.onEffects,
    this.activeTool,
  });

  // ---------------------------
  // TOOL ITEM BUILDER
  // ---------------------------
  /// Builds a single tool button with icon, label, and selection indicator.
  Widget _buildToolItem({
    required EditorTool tool,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isSelected = activeTool == tool;

    // Colors based on selection state
    final Color iconColor = isSelected ? Colors.white : Colors.white60;
    final Color labelColor = isSelected ? Colors.white : Colors.white60;
    final Color indicatorColor = isSelected ? Colors.white : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Icon ---
              Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(height: 6),

              // --- Label ---
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: labelColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),

              // --- Selection Indicator (animated underline) ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 2,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // BUILD METHOD
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      // --- Dark background with top border ---
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Dark grey like CapCut
        border: Border(
          top: BorderSide(
            color: Color(0xFF2A2A2A),
            width: 0.5,
          ),
        ),
      ),
      // --- Safe area for bottom navigation gesture area ---
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 2, bottom:2 ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // --- Audio Tool ---
              _buildToolItem(
                tool: EditorTool.audio,
                icon: Icons.music_note_outlined,
                label: 'Audio',
                onTap: onAudio,
              ),

              // --- Text Tool ---
              _buildToolItem(
                tool: EditorTool.text,
                icon: Icons.text_fields_outlined,
                label: 'Text',
                onTap: onText,
              ),

              // --- Effects Tool ---
              _buildToolItem(
                tool: EditorTool.effects,
                icon: Icons.auto_awesome_outlined,
                label: 'Effects',
                onTap: onEffects,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
