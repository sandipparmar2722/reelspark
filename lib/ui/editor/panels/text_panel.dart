import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

enum TextPanelTab { style, font }

class TextPanel extends StatefulWidget {
  final TextEditingController textController;
  final TextClip? selectedTextClip;

  final ValueChanged<String>? onTextChanged;
  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<double>? onOpacityChanged;
  final ValueChanged<String>? onFontFamilyChanged;
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
    'Roboto',
    'Montserrat',
    'Lobster',
    'Playfair',
    'Bebas',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildTextField(),
          const SizedBox(height: 10),
          _buildTabs(),
          const SizedBox(height: 8),
          if (_activeTab == TextPanelTab.style) _buildStylePanel(),
          if (_activeTab == TextPanelTab.font) _buildFontPanel(),
        ],
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Text',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onDone,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── TEXT FIELD ─────────────────

  Widget _buildTextField() {
    return TextField(
      controller: widget.textController,
      maxLines: 2,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Enter text',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: widget.onTextChanged,
    );
  }

  // ───────────────── TABS ─────────────────

  Widget _buildTabs() {
    return Row(
      children: [
        _tab('Style', TextPanelTab.style),
        const SizedBox(width: 18),
        _tab('Font', TextPanelTab.font),
      ],
    );
  }

  Widget _tab(String label, TextPanelTab tab) {
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ───────────────── STYLE PANEL ─────────────────

  Widget _buildStylePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.opacity, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: Slider(
                value: widget.selectedTextClip?.opacity ?? 1.0,
                min: 0.2,
                max: 1.0,
                onChanged: widget.onOpacityChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _textColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = _textColors[i];
              final selected = widget.selectedTextClip?.color == c;
              return GestureDetector(
                onTap: () => widget.onColorChanged?.call(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2,
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

  // ───────────────── FONT PANEL ─────────────────

  Widget _buildFontPanel() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fontFamilies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final font = _fontFamilies[i];
          final selected = widget.selectedTextClip?.fontFamily == font;
          return GestureDetector(
            onTap: () => widget.onFontFamilyChanged?.call(font),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white12 : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                ),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 16,
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
