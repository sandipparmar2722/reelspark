import 'package:reelspark/ui/editor/editor.dart';


/// Available tools in the editor bottom toolbar.
/// These map to specific editor actions (music, text, effects/transitions).
enum EditorTool {
  audio,
  text,
  effects,
  stikers,
}

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
  final VoidCallback stikers;

  // --- State ---
  final EditorTool? activeTool;

  const EditorBottomBar({
    super.key,
    required this.onAudio,
    required this.onText,
    required this.onEffects,
    required this.stikers,
    this.activeTool,
  });

  Widget _buildToolItem({
    required EditorTool tool,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isSelected = activeTool == tool;

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
              Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: labelColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2A2A2A),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolItem(
                tool: EditorTool.audio,
                icon: Icons.music_note_outlined,
                label: 'Audio',
                onTap: onAudio,
              ),
              _buildToolItem(
                tool: EditorTool.text,
                icon: Icons.text_fields_outlined,
                label: 'Text',
                onTap: onText,
              ),
              _buildToolItem(
                tool: EditorTool.effects,
                icon: Icons.auto_awesome_outlined,
                label: 'Effects',
                onTap: onEffects,
              ),
              _buildToolItem(
                tool: EditorTool.stikers,
                icon: Icons.tag_faces_outlined,
                label: 'stikers',
                onTap: stikers,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

