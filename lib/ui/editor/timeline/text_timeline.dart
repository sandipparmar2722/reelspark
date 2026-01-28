import 'package:reelspark/ui/editor/editor.dart';

/// Text timeline track widget
///
/// Displays text clips with:
/// - Trim handles
/// - Drag to move (long press)
/// - Timeline position sync
class TextTimeline extends StatefulWidget {
  final List<TextClip> textClips;
  final TextClip? selectedTextClip;
  final double timelineWidth;
  final double totalDuration;
  final Function(TextClip)? onTextClipSelect;
  final Function(TextClip, double, double)? onTextClipTrim;
  final Function(TextClip, double, double)? onTextClipMove;

  const TextTimeline({
    super.key,
    required this.textClips,
    required this.timelineWidth,
    required this.totalDuration,
    this.selectedTextClip,
    this.onTextClipSelect,
    this.onTextClipTrim,
    this.onTextClipMove,
  });

  @override
  State<TextTimeline> createState() => _TextTimelineState();
}

class _TextTimelineState extends State<TextTimeline> {
  TextClip? _draggingTextClip;
  double _textDragStartTime = 0;
  double _textDragEndTime = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimelineContainer.textTrackHeight,
      width: widget.timelineWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: widget.textClips.map((clip) {
          final left = clip.startTime * TimelineContainer.pixelsPerSecond;
          final width = (clip.duration * TimelineContainer.pixelsPerSecond)
              .clamp(24.0, double.infinity);
          final isSelected = widget.selectedTextClip?.id == clip.id;

          return Positioned(
            left: left,
            width: width,
            top: 2,
            bottom: 2,
            child: _TextClipWidget(
              clip: clip,
              isSelected: isSelected,
              isDragging: _draggingTextClip?.id == clip.id,
              pixelsPerSecond: TimelineContainer.pixelsPerSecond,
              totalDuration: widget.totalDuration,
              onTap: () => widget.onTextClipSelect?.call(clip),
              onTrimStart: (newStart, originalEnd) {
                widget.onTextClipTrim?.call(clip, newStart, originalEnd);
              },
              onTrimEnd: (originalStart, newEnd) {
                widget.onTextClipTrim?.call(clip, originalStart, newEnd);
              },
              onMoveStart: () {
                setState(() {
                  _draggingTextClip = clip;
                  _textDragStartTime = clip.startTime;
                  _textDragEndTime = clip.endTime;
                });
              },
              onMoveUpdate: (deltaSeconds) {
                if (_draggingTextClip?.id != clip.id) return;

                final duration = _textDragEndTime - _textDragStartTime;
                double newStart = _textDragStartTime + deltaSeconds;
                double newEnd = _textDragEndTime + deltaSeconds;

                // Clamp to valid range
                if (newStart < 0) {
                  newStart = 0;
                  newEnd = duration;
                }
                if (newEnd > widget.totalDuration) {
                  newEnd = widget.totalDuration;
                  newStart = newEnd - duration;
                }

                widget.onTextClipMove?.call(clip, newStart, newEnd);
              },
              onMoveEnd: () {
                setState(() {
                  _draggingTextClip = null;
                  _textDragStartTime = 0;
                  _textDragEndTime = 0;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual text clip widget with trim handles and drag-to-move
class _TextClipWidget extends StatefulWidget {
  final TextClip clip;
  final bool isSelected;
  final bool isDragging;
  final double pixelsPerSecond;
  final double totalDuration;
  final VoidCallback onTap;
  final Function(double newStart, double originalEnd) onTrimStart;
  final Function(double originalStart, double newEnd) onTrimEnd;
  final VoidCallback onMoveStart;
  final Function(double totalDeltaSeconds) onMoveUpdate;
  final VoidCallback onMoveEnd;

  const _TextClipWidget({
    required this.clip,
    required this.isSelected,
    required this.isDragging,
    required this.pixelsPerSecond,
    required this.totalDuration,
    required this.onTap,
    required this.onTrimStart,
    required this.onTrimEnd,
    required this.onMoveStart,
    required this.onMoveUpdate,
    required this.onMoveEnd,
  });

  @override
  State<_TextClipWidget> createState() => _TextClipWidgetState();
}

class _TextClipWidgetState extends State<_TextClipWidget> {
  bool _isDragging = false;
  double _originalStartTime = 0;
  double _originalEndTime = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade600,
        borderRadius: BorderRadius.circular(6),
        border: widget.isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: widget.isDragging || _isDragging
            ? [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // LEFT TRIM HANDLE
          _TextTrimHandle(
            pixelsPerSecond: widget.pixelsPerSecond,
            onDragStart: () {
              _originalStartTime = widget.clip.startTime;
              _originalEndTime = widget.clip.endTime;
            },
            onDrag: (deltaSeconds) {
              double newStart = _originalStartTime + deltaSeconds;
              newStart = newStart.clamp(0.0, _originalEndTime - 0.1);
              widget.onTrimStart(newStart, _originalEndTime);
            },
            onDragEnd: () {
              _originalStartTime = 0;
              _originalEndTime = 0;
            },
          ),

          // CENTER BODY
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onLongPressStart: (_) {
                setState(() => _isDragging = true);
                widget.onMoveStart();
              },
              onLongPressMoveUpdate: (details) {
                if (!_isDragging) return;
                final deltaSeconds =
                    details.localOffsetFromOrigin.dx / widget.pixelsPerSecond;
                widget.onMoveUpdate(deltaSeconds);
              },
              onLongPressEnd: (_) {
                setState(() => _isDragging = false);
                widget.onMoveEnd();
              },
              onLongPressCancel: () {
                setState(() => _isDragging = false);
                widget.onMoveEnd();
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.clip.text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // RIGHT TRIM HANDLE
          _TextTrimHandle(
            pixelsPerSecond: widget.pixelsPerSecond,
            onDragStart: () {
              _originalStartTime = widget.clip.startTime;
              _originalEndTime = widget.clip.endTime;
            },
            onDrag: (deltaSeconds) {
              double newEnd = _originalEndTime + deltaSeconds;
              newEnd = newEnd.clamp(_originalStartTime + 0.1, double.infinity);
              widget.onTrimEnd(_originalStartTime, newEnd);
            },
            onDragEnd: () {
              _originalStartTime = 0;
              _originalEndTime = 0;
            },
          ),
        ],
      ),
    );
  }
}

/// Trim handle for text clip (CapCut style)
class _TextTrimHandle extends StatefulWidget {
  final VoidCallback onDragStart;
  final Function(double deltaSeconds) onDrag;
  final VoidCallback onDragEnd;
  final double pixelsPerSecond;

  const _TextTrimHandle({
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.pixelsPerSecond,
  });

  @override
  State<_TextTrimHandle> createState() => _TextTrimHandleState();
}

class _TextTrimHandleState extends State<_TextTrimHandle> {
  double _accumulatedDelta = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        _accumulatedDelta = 0;
        _isDragging = true;
        widget.onDragStart();
      },
      onHorizontalDragUpdate: (details) {
        if (!_isDragging) return;
        _accumulatedDelta += details.delta.dx;
        final deltaSeconds = _accumulatedDelta / widget.pixelsPerSecond;
        widget.onDrag(deltaSeconds);
      },
      onHorizontalDragEnd: (details) {
        _isDragging = false;
        _accumulatedDelta = 0;
        widget.onDragEnd();
      },
      onHorizontalDragCancel: () {
        _isDragging = false;
        _accumulatedDelta = 0;
        widget.onDragEnd();
      },
      child: Container(
        width: 12,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isDragging ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

