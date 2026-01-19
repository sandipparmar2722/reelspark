import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reelspark/models/audio_clip.dart';

class TimelineWidget extends StatefulWidget {
  final List<File> images;
  final List<double> durations;
  final int selectedIndex;
  final bool isPlaying;

  final Function(int) onSelect;
  final Function(List<File>, List<double>) onReorder;
  final Function(double) onDurationChange;
  final Function(double)? onTimelineScroll;

  final VoidCallback? onAddEffect;
  final Future<void> Function()? onAddImage;

  /// Audio clip with trim support (replaces simple musicPath/duration)
  final AudioClip? audioClip;

  /// Callback when audio clip trim values change
  final Function(AudioClip)? onAudioClipChanged;

  static final ScrollController scrollController = ScrollController();

  const TimelineWidget({
    super.key,
    required this.images,
    required this.durations,
    required this.selectedIndex,
    required this.isPlaying,
    required this.onSelect,
    required this.onReorder,
    required this.onDurationChange,
    this.audioClip,
    this.onAudioClipChanged,
    this.onTimelineScroll,
    this.onAddEffect,
    this.onAddImage,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  // ================= CONSTANTS =================
  static const double _pixelsPerSecond = 60.0;
  static const double _gapWidth = 24.0;
  static const double _minDuration = 0.5;
  static const double _maxDuration = 10.0;
  static const double _rulerHeight = 24.0;
  static const double _clipHeight = 56.0;
  static const double _handleWidth = 16.0;
  static const double _audioTrackHeight = 40.0; // Fixed audio track height
  static const double _trackSpacing = 8.0; // Space between tracks

  static const double _edgeScrollThreshold = 40;
  static const double _autoScrollSpeed = 6;

  late ScrollController _scrollController;

  // Video clip resize state
  int _draggingEdge = 0;
  int _resizingIndex = -1;
  double _resizeAccumulatedDx = 0;

  // Audio clip resize state
  int _audioTrimEdge = 0; // -1 = left, 1 = right, 0 = none
  double _audioTrimAccumulatedDx = 0;
  bool _isAudioSelected = false;

  // Continuous auto-scroll state for audio trimming
  Timer? _autoScrollTimer;
  double _currentTrimDragX = 0; // Current drag X position on screen
  bool _isAudioTrimming = false;


  @override
  void initState() {
    super.initState();
    _scrollController = TimelineWidget.scrollController; // ✅ SHARED

    // Listen for manual scrolling
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.onTimelineScroll == null ||
        !_scrollController.hasClients ||
        mounted == false) return;

    // 🚫 Ignore scroll events while playing
    if (widget.isPlaying) return;

    // ✅ Calculate max time and clamp to prevent exceeding duration
    final maxTime = widget.durations.reduce((a, b) => a + b);
    final timePosition =
        (_scrollController.offset / _pixelsPerSecond).clamp(0.0, maxTime);

    widget.onTimelineScroll!(timePosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // ================= SMOOTH RESIZE CORE =================

  void _handleResizeDrag({
    required int index,
    required double deltaDx,
  }) {
    _resizeAccumulatedDx += deltaDx;

    final deltaSeconds = _resizeAccumulatedDx / _pixelsPerSecond;

    if (deltaSeconds.abs() < 0.02) return;

    _resizeAccumulatedDx = 0;

    final current = widget.durations[index];
    final next = (current + deltaSeconds).clamp(
      _minDuration,
      _maxDuration,
    );

    if (next != current) {
      widget.onDurationChange(next);
      _autoScrollWhileResizing();
    }
  }

  void _autoScrollWhileResizing() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    final offset = pos.pixels;
    final max = pos.maxScrollExtent;

    if (offset > max - _edgeScrollThreshold) {
      _scrollController.jumpTo(
        (offset + _autoScrollSpeed).clamp(0, max),
      );
    }

    if (offset < _edgeScrollThreshold) {
      _scrollController.jumpTo(
        (offset - _autoScrollSpeed).clamp(0, max),
      );
    }
  }

  // ================= CONTINUOUS AUTO-SCROLL FOR AUDIO TRIMMING =================

  /// Start continuous auto-scroll timer based on drag position
  void _startContinuousAutoScroll(BuildContext context) {
    // Cancel any existing timer
    _autoScrollTimer?.cancel();

    // Start new timer at 60 FPS
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isAudioTrimming || !_scrollController.hasClients) {
        _stopContinuousAutoScroll();
        return;
      }

      _performAutoScroll(context);
    });
  }

  /// Stop continuous auto-scroll timer
  void _stopContinuousAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// Perform auto-scroll based on current drag position
  void _performAutoScroll(BuildContext context) {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const edgeThreshold = 80.0; // Pixels from edge to trigger scroll
    const fastScrollSpeed = 12.0; // Faster scroll speed for audio trimming

    final position = _scrollController.position;
    final currentOffset = position.pixels;
    final maxOffset = position.maxScrollExtent;

    // Scroll left (drag near left edge)
    if (_currentTrimDragX < edgeThreshold && currentOffset > 0) {
      final scrollAmount = fastScrollSpeed * (1 - _currentTrimDragX / edgeThreshold);
      _scrollController.jumpTo((currentOffset - scrollAmount).clamp(0.0, maxOffset));
    }
    // Scroll right (drag near right edge)
    else if (_currentTrimDragX > screenWidth - edgeThreshold && currentOffset < maxOffset) {
      final edgeDistance = screenWidth - _currentTrimDragX;
      final scrollAmount = fastScrollSpeed * (1 - edgeDistance / edgeThreshold);
      _scrollController.jumpTo((currentOffset + scrollAmount).clamp(0.0, maxOffset));
    }
  }



  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate timeline width based on video clips
    final videoTimelineWidth = widget.durations.fold<double>(
      0,
      (sum, d) => sum + d * _pixelsPerSecond,
    ) + (widget.images.length - 1) * _gapWidth;

    // Audio track width based on audio clip duration (trimmed)
    final audioTimelineWidth = widget.audioClip != null
        ? widget.audioClip!.duration * _pixelsPerSecond
        : 0.0;

    // Use the longer of the two for total timeline width
    final timelineWidth = videoTimelineWidth > audioTimelineWidth
        ? videoTimelineWidth
        : audioTimelineWidth;

    final sidePadding = screenWidth / 2;

    return Container(
      color: const Color(0xFF0E0E0E),
      child: Stack(
        children: [
          // Scrollable Timeline Content - Multi-track layout
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: SizedBox(
                width: timelineWidth + 50, // Extra padding at end
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════ TIME RULER ═══════
                    _buildTimeRuler(timelineWidth),

                    const SizedBox(height: _trackSpacing),

                    // ═══════ VIDEO TRACK ═══════
                    _buildVideoTrack(),

                    // ═══════ AUDIO TRACK (if audio clip exists) ═══════
                    if (widget.audioClip != null) ...[
                      const SizedBox(height: _trackSpacing),
                      _buildAudioTrack(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // CENTER PLAYHEAD LINE
          Positioned(
            left: screenWidth / 2 - 1,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(width: 2, color: Colors.white),
            ),
          ),

          // PLAYHEAD TRIANGLE
          Positioned(
            left: screenWidth / 2 - 6,
            top: 0,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(12, 8),
                painter: _PlayheadTrianglePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= VIDEO TRACK ═══════════════════════════
  Widget _buildVideoTrack() {
    return SizedBox(
      height: _clipHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.images.length * 2 - 1, (i) {
            if (i.isEven) {
              return _buildClipWidget(i ~/ 2);
            }
            return SizedBox(
              width: _gapWidth,
              height: 28,
              child: Center(child: _buildBetweenAddButton()),
            );
          }),
        ],
      ),
    );
  }

  // ================= AUDIO TRACK WITH TRIM HANDLES ═══════════════════════════
  Widget _buildAudioTrack() {
    final audioClip = widget.audioClip!;
    final audioWidth = audioClip.duration * _pixelsPerSecond;
    final isSelected = _isAudioSelected;
    final isTrimming = _audioTrimEdge != 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAudioSelected = !_isAudioSelected;
          // Deselect video clips when audio is selected
          if (_isAudioSelected) {
            _resizingIndex = -1;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _audioTrackHeight,
        width: audioWidth > 0 ? audioWidth : 100,
        margin: EdgeInsets.only(left: audioClip.startTime * _pixelsPerSecond),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: isSelected ? 0.4 : 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.greenAccent.withValues(alpha: 0.6),
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  // Left spacer for handle
                  const SizedBox(width: 12),

                  // Music content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              audioClip.fileName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          // Duration badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${audioClip.duration.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right spacer for handle
                  const SizedBox(width: 12),
                ],
              ),
            ),

            // ═══════ LEFT TRIM HANDLE ═══════
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _audioTrimEdge = -1;
                      _audioTrimAccumulatedDx = 0;
                      _isAudioTrimming = true;
                      _currentTrimDragX = details.globalPosition.dx;
                    });
                    // Start continuous auto-scroll
                    _startContinuousAutoScroll(context);
                  },
                  onHorizontalDragUpdate: (details) {
                    // Update drag position for auto-scroll
                    setState(() {
                      _currentTrimDragX = details.globalPosition.dx;
                    });

                    // Handle trim logic
                    _handleAudioTrimDrag(
                      deltaDx: details.delta.dx,
                      isLeftHandle: true,
                    );
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() {
                      _audioTrimEdge = 0;
                      _isAudioTrimming = false;
                    });
                    // Stop continuous auto-scroll
                    _stopContinuousAutoScroll();
                  },
                  child: _buildAudioTrimHandle(isLeft: true, isActive: isTrimming && _audioTrimEdge == -1),
                ),
              ),

            // ═══════ RIGHT TRIM HANDLE ═══════
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _audioTrimEdge = 1;
                      _audioTrimAccumulatedDx = 0;
                      _isAudioTrimming = true;
                      _currentTrimDragX = details.globalPosition.dx;
                    });
                    // Start continuous auto-scroll
                    _startContinuousAutoScroll(context);
                  },
                  onHorizontalDragUpdate: (details) {
                    // Update drag position for auto-scroll
                    setState(() {
                      _currentTrimDragX = details.globalPosition.dx;
                    });

                    // Handle trim logic
                    _handleAudioTrimDrag(
                      deltaDx: details.delta.dx,
                      isLeftHandle: false,
                    );
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() {
                      _audioTrimEdge = 0;
                      _isAudioTrimming = false;
                    });
                    // Stop continuous auto-scroll
                    _stopContinuousAutoScroll();
                  },
                  child: _buildAudioTrimHandle(isLeft: false, isActive: isTrimming && _audioTrimEdge == 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════ AUDIO TRIM HANDLE WIDGET ═══════
  Widget _buildAudioTrimHandle({required bool isLeft, required bool isActive}) {
    return Container(
      width: _handleWidth,
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent : Colors.green,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(6) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(6),
        ),
      ),
      child: Center(
        child: Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ═══════ AUDIO TRIM DRAG HANDLER ═══════
  void _handleAudioTrimDrag({
    required double deltaDx,
    required bool isLeftHandle,
  }) {
    if (widget.audioClip == null || widget.onAudioClipChanged == null) return;

    _audioTrimAccumulatedDx += deltaDx;

    final deltaSeconds = _audioTrimAccumulatedDx / _pixelsPerSecond;

    // Only update when we have accumulated enough movement
    if (deltaSeconds.abs() < 0.02) return;

    _audioTrimAccumulatedDx = 0;

    final audioClip = widget.audioClip!;
    AudioClip updatedClip;

    if (isLeftHandle) {
      // Left handle adjusts trimStart
      final newTrimStart = (audioClip.trimStart + deltaSeconds).clamp(
        0.0,
        audioClip.trimEnd - AudioClip.minDuration,
      );
      updatedClip = audioClip.copyWith(trimStart: newTrimStart);
    } else {
      // Right handle adjusts trimEnd
      final newTrimEnd = (audioClip.trimEnd + deltaSeconds).clamp(
        audioClip.trimStart + AudioClip.minDuration,
        audioClip.originalDuration,
      );
      updatedClip = audioClip.copyWith(trimEnd: newTrimEnd);
    }

    // Notify parent of the change
    widget.onAudioClipChanged!(updatedClip);

    // Note: Auto-scroll is handled by continuous timer in _startContinuousAutoScroll
    // No need to call _autoScrollWhileResizing() here
  }

  // ================= ADD BUTTON BETWEEN CLIPS =================
  Widget _buildBetweenAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onAddEffect,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  // ================= TIME RULER =================
  Widget _buildTimeRuler(double width) {
    final seconds = (width / _pixelsPerSecond).ceil();

    return SizedBox(
      height: _rulerHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(seconds + 1, (i) {
          return SizedBox(
            width: _pixelsPerSecond,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 1, height: 8, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  _formatTime(i.toDouble()),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatTime(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }


  //// ================= DRAGGING CLIP =================
  Widget _buildClipContent(int index) {
    final duration = widget.durations[index];
    final width = duration * _pixelsPerSecond;
    final selected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: _clipHeight,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
          ),
        ),
        child: Stack(
          children: [
            Image.file(
              widget.images[index],
              fit: BoxFit.cover,
              width: width,
              height: _clipHeight,
            ),

            // duration badge
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





  //// ================= DRAGGING CLIP =================
  Widget _buildDraggingClip(int index) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.9,
        child: _buildClipContent(index),
      ),
    );
  }

  /// Reorders clips when dragged and dropped.

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

  // ================= CLIP =================
  Widget _buildClipWidget(int index) {
    final selected = widget.selectedIndex == index;

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 500), // Longer delay to allow tap and resize gestures
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _buildDraggingClip(index),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildClipContent(index),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          _reorderClips(details.data, index);
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Main clip content
              _buildClipContent(index),

              // Left resize handle (only show when selected)
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _resizingIndex = index;
                        _draggingEdge = -1;
                        _resizeAccumulatedDx = 0;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleResizeDrag(
                        index: index,
                        deltaDx: -details.delta.dx, // Negative for left handle
                      );
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() {
                        _resizingIndex = -1;
                        _draggingEdge = 0;
                      });
                    },
                    child: _buildResizeHandle(true, index),
                  ),
                ),

              // Right resize handle (only show when selected)
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
                        deltaDx: details.delta.dx, // Positive for right handle
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

  Widget _buildResizeHandle(bool left, int index) {
    final active = _resizingIndex == index &&
        ((left && _draggingEdge == -1) ||
            (!left && _draggingEdge == 1));

    return Container(
      width: _handleWidth,
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
}

// ================= PLAYHEAD TRIANGLE =================
class _PlayheadTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
