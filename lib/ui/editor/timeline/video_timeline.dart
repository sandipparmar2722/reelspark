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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimelineContainer.clipHeight,
      child: Row(
        children: List.generate(widget.images.length * 2 - 1, (i) {
          if (i.isEven) {
            return _buildClipWidget(i ~/ 2);
          } else {
            return _buildTransitionButton(context, (i - 1) ~/ 2);
          }
        }),
      )

    );
  }

  Widget _buildTransitionButton(BuildContext context, int index) {
    final hasTransition = widget.transitions[index] != null;

    return GestureDetector(
      onTap: () => widget.onAddTransition(index),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: hasTransition ? Colors.orangeAccent : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(
          hasTransition ? Icons.auto_awesome : Icons.add,
          size: 14,
          color: Colors.white,
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
    final width = duration * TimelineContainer.pixelsPerSecond;
    final selected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: TimelineContainer.clipHeight,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                widget.images[index],
                fit: BoxFit.cover,
                width: width,
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

    return Container(
      width: TimelineContainer.handleWidth,
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(4) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(4),
        ),
      ),
      child: const Center(child: SizedBox(width: 3, height: 20)),
    );
  }

  void _handleResizeDrag({required int index, required double deltaDx}) {
    _resizeAccumulatedDx += deltaDx;

    final deltaSeconds = _resizeAccumulatedDx / TimelineContainer.pixelsPerSecond;
    if (deltaSeconds.abs() < 0.02) return;

    _resizeAccumulatedDx = 0;

    final current = widget.durations[index];
    final next = (current + deltaSeconds).clamp(
      VideoTimeline.minDuration,
      VideoTimeline.maxDuration,
    );

    if (next != current) {
      widget.onDurationChange(next);
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

