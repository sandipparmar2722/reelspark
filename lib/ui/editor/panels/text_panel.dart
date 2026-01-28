import 'package:reelspark/ui/editor/editor.dart';

/// Text panel tabs
enum TextPanelTab { style, font }

/// Text input and styling panel widget
///
/// Contains:
/// - Text input field
/// - Style/Font tab selector
/// - Color picker
/// - Opacity slider
/// - Font family selector
class TextPanel extends StatefulWidget {
  /// Text editing controller
  final TextEditingController textController;

  /// Currently selected text clip
  final TextClip? selectedTextClip;

  /// Callback when text changes
  final Function(String)? onTextChanged;

  /// Callback when color changes
  final Function(Color)? onColorChanged;

  /// Callback when opacity changes
  final Function(double)? onOpacityChanged;

  /// Callback when font family changes
  final Function(String)? onFontFamilyChanged;

  /// Callback when done button is pressed
  final VoidCallback? onDone;

  const TextPanel({
    super.key,
    required this.textController,
    this.selectedTextClip,
    this.onTextChanged,
    this.onColorChanged,
    this.onOpacityChanged,
    this.onFontFamilyChanged,
    this.onDone,
  });

  @override
  State<TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<TextPanel> {
  TextPanelTab _activeTab = TextPanelTab.style;

  // CapCut-style color palette
  static const List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Color(0xFFBDBDBD),
    Color(0xFF757575),
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.cyan,
    Colors.green,
  ];

  static const List<String> _fontFamilies = [
    'Poppins',
    'Montserrat',
    'Lobster',
    'Playfair',
    'Bebas',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Input Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: widget.textController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter text',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: widget.onTextChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDone,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Style | Font Tabs
          Row(
            children: [
              _buildTab(
                label: 'Style',
                isActive: _activeTab == TextPanelTab.style,
                onTap: () => setState(() => _activeTab = TextPanelTab.style),
              ),
              const SizedBox(width: 12),
              _buildTab(
                label: 'Font',
                isActive: _activeTab == TextPanelTab.font,
                onTap: () => setState(() => _activeTab = TextPanelTab.font),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 6),

          // Panel Content
          if (_activeTab == TextPanelTab.style) _buildStylePanel(),
          if (_activeTab == TextPanelTab.font) _buildFontPanel(),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStylePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opacity Row
        Row(
          children: [
            const Icon(Icons.opacity, color: Colors.white54, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: widget.selectedTextClip?.opacity ?? 1.0,
                  min: 0.2,
                  max: 1.0,
                  onChanged: (v) => widget.onOpacityChanged?.call(v),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Color Styles
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _textColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final color = _textColors[index];
              final isSelected = widget.selectedTextClip?.color == color;

              return GestureDetector(
                onTap: () => widget.onColorChanged?.call(color),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontFamily: widget.selectedTextClip?.fontFamily ?? 'Poppins',
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontPanel() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fontFamilies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final font = _fontFamilies[index];
          final isSelected = widget.selectedTextClip?.fontFamily == font;

          return GestureDetector(
            onTap: () => widget.onFontFamilyChanged?.call(font),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white12 : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                ),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

