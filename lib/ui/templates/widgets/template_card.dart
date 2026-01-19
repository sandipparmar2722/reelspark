import '../templates.dart';

import 'package:flutter/material.dart';

import '../models/video_template.dart';

class TemplateCard extends StatefulWidget {
  final VideoTemplate template;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  Color _getEffectColor(String effect) {
    switch (effect) {
      case 'warm':
        return const Color(0xFFFF7A00); // Orange
      case 'cool':
        return const Color(0xFF00A3FF); // Blue
      case 'cinematic':
        return const Color(0xFF2D3748); // Dark slate
      case 'bw':
        return const Color(0xFF6B7280); // Gray
      case 'film':
        return const Color(0xFF8B7355); // Sepia brown
      case 'vignette':
        return const Color(0xFF4A5568); // Dark gray
      case 'blur':
        return const Color(0xFF60A5FA); // Soft blue
      case 'glitch':
        return const Color(0xFFEC4899); // Pink
      case 'default':
      default:
        return const Color(0xFF374151); // Neutral gray
    }
  }


  String _getTransitionLabel(String transition) {
    switch (transition) {
      case 'fade':
        return 'Fade';
      case 'slide_left':
        return 'Slide ←';
      case 'slide_up':
        return 'Slide ↑';
      case 'wipe':
        return 'Wipe';
      case 'zoom':
        return 'Zoom';
      case 'cut':
        return 'Cut';
      default:
        return transition;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final effectColor = _getEffectColor(widget.template.effect);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview area (placeholder) - tall like CapCut.
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectColor.withValues(alpha: 0.18),
                        effectColor.withValues(alpha: 0.08),
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _Badge(
                        text: _getTransitionLabel(widget.template.transition),
                        bg: Colors.white.withValues(alpha: 0.92),
                        fg: Colors.black87,
                        border: Colors.black12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom text area
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.template.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 14, color: Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.template.resolvedSlots} photos',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color border;
  final FontWeight fontWeight;

  const _Badge({
    required this.text,
    required this.bg,
    required this.fg,
    required this.border,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
