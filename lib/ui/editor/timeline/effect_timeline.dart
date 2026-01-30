import '../../templates/templates.dart';
import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

const double _handleWidth = 22;
const double _minEffectDuration = 0.8;

class EffectTimeline extends StatelessWidget {
  final List<EffectClip> effects;
  final double totalDuration;
  final Function(EffectClip) onSelect;
  final Function(EffectClip, double, double) onMove;

  /// lock / unlock timeline scroll
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const EffectTimeline({
    super.key,
    required this.effects,
    required this.totalDuration,
    required this.onSelect,
    required this.onMove,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        children: effects.map((clip) {
          final left =
              clip.startTime * TimelineContainer.pixelsPerSecond;
          // Ensure width respects minimum duration to prevent overflow
          final effectiveDuration = clip.duration.clamp(_minEffectDuration, double.infinity);
          final width =
              effectiveDuration * TimelineContainer.pixelsPerSecond;

          return Positioned(
            left: left,
            width: width,
            top: 4,
            bottom: 4,
            child: _EffectClipWidget(
              clip: clip,
              totalDuration: totalDuration,
              onSelect: onSelect,
              onMove: onMove,
              onDragStart: onDragStart,
              onDragEnd: onDragEnd,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// EFFECT CLIP (CAPCUT-STYLE MOVE + RESIZE)
// ============================================================

class _EffectClipWidget extends StatefulWidget {
  final EffectClip clip;
  final double totalDuration;
  final Function(EffectClip) onSelect;
  final Function(EffectClip, double, double) onMove;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _EffectClipWidget({
    required this.clip,
    required this.totalDuration,
    required this.onSelect,
    required this.onMove,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<_EffectClipWidget> createState() => _EffectClipWidgetState();
}

class _EffectClipWidgetState extends State<_EffectClipWidget> {
  bool _moving = false;
  bool _resizeLeft = false;
  bool _resizeRight = false;
  bool _isAtMinDurationLeft = false;
  bool _isAtMinDurationRight = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onDragStart(),
      onPointerUp: (_) => widget.onDragEnd(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        /// TAP → select
        onTap: () => widget.onSelect(widget.clip),

        /// MOVE EFFECT
        onPanStart: (_) => setState(() => _moving = true),
        onPanEnd: (_) => setState(() => _moving = false),
        onPanUpdate: (details) {
          if (_resizeLeft || _resizeRight) return;

          final delta =
              details.delta.dx / TimelineContainer.pixelsPerSecond;

          final newStart =
          (widget.clip.startTime + delta)
              .clamp(
            0.0,
            widget.totalDuration - widget.clip.duration,
          );

          widget.onMove(
            widget.clip,
            newStart,
            newStart + widget.clip.duration,
          );
        },

        child: Stack(
          children: [
            // ================= EFFECT BODY =================
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: (_isAtMinDurationLeft || _isAtMinDurationRight)
                    ? Colors.red.withValues(alpha: 0.85)
                    : Colors.orangeAccent.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (_moving || _resizeLeft || _resizeRight)
                      ? Colors.white
                      : (_isAtMinDurationLeft || _isAtMinDurationRight)
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.transparent,
                  width: (_isAtMinDurationLeft || _isAtMinDurationRight) ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.clip.type.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (_isAtMinDurationLeft || _isAtMinDurationRight)
                    Text(
                      'MIN: ${_minEffectDuration}s',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            // ================= LEFT HANDLE =================
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _handleWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) =>
                    setState(() => _resizeLeft = true),
                onPanEnd: (_) =>
                    setState(() {
                      _resizeLeft = false;
                      _isAtMinDurationLeft = false;
                    }),
                onPanUpdate: (details) {
                  final delta =
                      details.delta.dx /
                          TimelineContainer.pixelsPerSecond;

                  final currentDuration = widget.clip.duration;
                  final requestedStart = widget.clip.startTime + delta;
                  final requestedDuration = widget.clip.endTime - requestedStart;

                  final newStart =
                  requestedStart.clamp(
                    0.0,
                    widget.clip.endTime - _minEffectDuration,
                  );

                  // Check if we're trying to go below minimum duration
                  final atMinDuration = (currentDuration <= _minEffectDuration && delta > 0) ||
                                        (requestedDuration < _minEffectDuration && delta > 0);
                  if (_isAtMinDurationLeft != atMinDuration) {
                    setState(() {
                      _isAtMinDurationLeft = atMinDuration;
                    });
                  }

                  widget.onMove(
                    widget.clip,
                    newStart,
                    widget.clip.endTime,
                  );
                },
                child: _CapCutResizeHandle(
                  active: _resizeLeft,
                  left: true,
                  isAtLimit: _isAtMinDurationLeft,
                ),
              ),
            ),

            // ================= RIGHT HANDLE =================
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _handleWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) =>
                    setState(() => _resizeRight = true),
                onPanEnd: (_) =>
                    setState(() {
                      _resizeRight = false;
                      _isAtMinDurationRight = false;
                    }),
                onPanUpdate: (details) {
                  final delta =
                      details.delta.dx /
                          TimelineContainer.pixelsPerSecond;

                  final currentDuration = widget.clip.duration;
                  final requestedEnd = widget.clip.endTime + delta;
                  final requestedDuration = requestedEnd - widget.clip.startTime;

                  final newEnd =
                  requestedEnd.clamp(
                    widget.clip.startTime + _minEffectDuration,
                    widget.totalDuration,
                  );

                  // Check if we're trying to go below minimum duration
                  final atMinDuration = (currentDuration <= _minEffectDuration && delta < 0) ||
                                        (requestedDuration < _minEffectDuration && delta < 0);
                  if (_isAtMinDurationRight != atMinDuration) {
                    setState(() {
                      _isAtMinDurationRight = atMinDuration;
                    });
                  }

                  widget.onMove(
                    widget.clip,
                    widget.clip.startTime,
                    newEnd,
                  );
                },
                child: _CapCutResizeHandle(
                  active: _resizeRight,
                  left: false,
                  isAtLimit: _isAtMinDurationRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CAPCUT-STYLE HANDLE UI
// ============================================================

class _CapCutResizeHandle extends StatelessWidget {
  final bool active;
  final bool left;
  final bool isAtLimit;

  const _CapCutResizeHandle({
    required this.active,
    required this.left,
    this.isAtLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.black.withValues(alpha: active ? 0.45 : 0.25),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: isAtLimit
            ? Icon(
                Icons.lock,
                size: 12,
                color: Colors.red,
              )
            : Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white70,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
      ),
    );
  }
}
