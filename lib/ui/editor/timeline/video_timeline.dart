import 'package:reelspark/ui/editor/editor.dart';


/// Video timeline track widget
///
/// Displays video/image clips with:
/// - Thumbnails
/// - Resize handles
/// - Drag to reorder
/// - Duration display
class VideoTimeline extends StatefulWidget {
  final List<File> images;
  final List<double> durations;
  final int selectedIndex;
  final Function(int) onSelect;
  final Function(List<File>, List<double>) onReorder;
  final Function(double) onDurationChange;
  final VoidCallback? onAddEffect;

  final VoidCallback? onDurationDragStart; // ✅ ADD
  final Function(int) onAddTransition;
  final VoidCallback? onDurationDragEnd;   //
  final List<ClipTransition?> transitions;



  static const double minDuration = 0.5;
  static const double maxDuration = 10.0;

  const VideoTimeline({
    super.key,
    required this.images,
    required this.durations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onReorder,
    required this.onDurationChange,
    required this.transitions,
    required this.onAddTransition,
    this.onAddEffect,
    this.onDurationDragStart,
    this.onDurationDragEnd,

  });

  @override
  State<VideoTimeline> createState() => _VideoTimelineState();
}

class _VideoTimelineState extends State<VideoTimeline> {
  int _draggingEdge = 0;
  int _resizingIndex = -1;
  double _resizeAccumulatedDx = 0;
  bool _isAtMinDuration = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimelineContainer.clipHeight,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.images.length,
                (i) => _buildClipWidget(i),
          ),
        ),
      ),
    );
  }



  Widget _buildClipWidget(int index) {
    final selected = widget.selectedIndex == index;

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 500),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _buildDraggingClip(index),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildClipContent(index),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) => _reorderClips(details.data, index),
        builder: (context, candidateData, rejectedData) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildClipContent(index),

              // Left resize handle
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      widget.onDurationDragEnd?.call(); // ✅ COMMIT UNDO SNAPSHOT

                      setState(() {
                        _resizingIndex = index;
                        _draggingEdge = -1;
                        _resizeAccumulatedDx = 0;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleResizeDrag(
                        index: index,
                        deltaDx: -details.delta.dx,
                      );
                    },
                    onHorizontalDragEnd: (_) {
                      widget.onDurationDragEnd?.call(); // ✅ COMMIT UNDO SNAPSHOT
                      setState(() {
                        _resizingIndex = -1;
                        _draggingEdge = 0;
                        _isAtMinDuration = false;
                      });
                    },
                    child: _buildResizeHandle(true, index),
                  ),
                ),

              // Right resize handle
              if (selected)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _resizingIndex = index;
                        _draggingEdge = 1;
                        _resizeAccumulatedDx = 0;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleResizeDrag(
                        index: index,
                        deltaDx: details.delta.dx,
                      );
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() {
                        _resizingIndex = -1;
                        _draggingEdge = 0;
                        _isAtMinDuration = false;
                      });
                    },
                    child: _buildResizeHandle(false, index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClipContent(int index) {
    final duration = widget.durations[index];
    final width =
    (duration * TimelineContainer.pixelsPerSecond).floorToDouble();

    final selected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: (width).floorToDouble(), // ✅ prevent fractional pixel overflow
        height: TimelineContainer.clipHeight,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 1, // visual only, no layout impact
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: (width).floorToDouble(),
                  height: TimelineContainer.clipHeight,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black54,
                  child: Text(
                    '${duration.toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggingClip(int index) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.9,
        child: _buildClipContent(index),
      ),
    );
  }

  Widget _buildResizeHandle(bool left, int index) {
    final active = _resizingIndex == index &&
        ((left && _draggingEdge == -1) || (!left && _draggingEdge == 1));

    // Show red when at minimum duration and trying to decrease
    final isAtLimit = _isAtMinDuration && active;

    return Container(
      width: TimelineContainer.handleWidth,
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red : (active ? Colors.blue : Colors.white),
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(4) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(4),
        ),
      ),
      child: Center(
        child: Icon(
          isAtLimit ? Icons.lock : Icons.drag_handle,
          size: 12,
          color: Colors.black54,
        ),
      ),
    );
  }

  void _handleResizeDrag({required int index, required double deltaDx}) {
    _resizeAccumulatedDx += deltaDx;

    final deltaSeconds = _resizeAccumulatedDx / TimelineContainer.pixelsPerSecond;
    if (deltaSeconds.abs() < 0.02) return;

    _resizeAccumulatedDx = 0;

    final current = widget.durations[index];
    final requested = current + deltaSeconds;

    // Check if we're trying to go below minimum duration for visual feedback
    final atMinDuration = (current <= VideoTimeline.minDuration && deltaSeconds < 0) ||
                          (requested < VideoTimeline.minDuration && deltaSeconds < 0);
    if (_isAtMinDuration != atMinDuration) {
      setState(() {
        _isAtMinDuration = atMinDuration;
      });
    }

    // Only apply change if not trying to go below minimum
    if (requested >= VideoTimeline.minDuration || deltaSeconds > 0) {
      final next = requested.clamp(
        VideoTimeline.minDuration,
        VideoTimeline.maxDuration,
      );

      if (next != current) {
        widget.onDurationChange(next);
      }
    }
  }

  void _reorderClips(int from, int to) {
    if (from == to) return;

    final images = List<File>.from(widget.images);
    final durations = List<double>.from(widget.durations);

    final img = images.removeAt(from);
    final dur = durations.removeAt(from);

    images.insert(to, img);
    durations.insert(to, dur);

    widget.onReorder(images, durations);
  }
}

