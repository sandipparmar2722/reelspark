import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reelspark/ui/editor/editor.dart';

import 'video_timeline.dart';
import 'text_timeline.dart';
import 'audio_timeline.dart';
import 'effect_timeline.dart'; // ✅ ADD
import 'package:reelspark/models/effect_clip.dart'; // ✅ ADD

/// Main timeline container widget
class TimelineContainer extends StatefulWidget {
  final List<File> images;
  final List<double> durations;
  final int selectedIndex;
  final bool isPlaying;

  final List<ClipTransition?> transitions;
  final Function(int index) onAddTransition;

  final VoidCallback? onDurationDragStart;
  final VoidCallback? onDurationDragEnd;

  final Function(int) onSelect;
  final Function(List<File>, List<double>) onReorder;
  final Function(double) onDurationChange;
  final Function(double)? onTimelineScroll;

  final VoidCallback? onAddEffect;
  final Future<void> Function()? onAddImage;

  /// Audio
  final AudioClip? audioClip;
  final Function(AudioClip)? onAudioClipChanged;

  /// Text
  final List<TextClip> textClips;
  final TextClip? selectedTextClip;
  final Function(TextClip)? onTextClipSelect;
  final Function(TextClip, double, double)? onTextClipTrim;
  final Function(TextClip, double, double)? onTextClipMove;

  /// ✅ EFFECTS (ADDED – nothing removed)
  final List<EffectClip> effectClips;
  final Function(EffectClip) onEffectSelect;
  final Function(EffectClip, double, double) onEffectMove;

  static final ScrollController scrollController = ScrollController();

  static const double pixelsPerSecond = 60.0;
  static const double gapWidth = 24.0;
  static const double rulerHeight = 24.0;
  static const double clipHeight = 56.0;
  static const double handleWidth = 16.0;
  static const double audioTrackHeight = 40.0;
  static const double textTrackHeight = 36.0;
  static const double trackSpacing = 8.0;

  const TimelineContainer({
    super.key,
    required this.images,
    required this.durations,
    required this.selectedIndex,
    required this.isPlaying,
    required this.onSelect,
    required this.onReorder,
    required this.onDurationChange,
    this.onDurationDragStart,
    this.onDurationDragEnd,
    this.audioClip,
    this.onAudioClipChanged,
    this.onTimelineScroll,
    this.onAddEffect,
    this.onAddImage,
    this.textClips = const [],
    this.selectedTextClip,
    this.onTextClipSelect,
    this.onTextClipTrim,
    this.onTextClipMove,
    required this.transitions,
    required this.onAddTransition,

    // ✅ EFFECT PARAMS
    required this.effectClips,
    required this.onEffectSelect,
    required this.onEffectMove,
  });

  @override
  State<TimelineContainer> createState() => _TimelineContainerState();
}

class _TimelineContainerState extends State<TimelineContainer> {
  late ScrollController _scrollController;
  bool _isEffectDragging = false;



  List<Widget> _buildScrollableTransitionButtons() {
    final List<Widget> widgets = [];

    double left = 0;

    for (int i = 0; i < widget.durations.length - 1; i++) {
      // move to END of current clip
      left += widget.durations[i] * TimelineContainer.pixelsPerSecond;

      widgets.add(
        Positioned(
          left: left - 12, // perfectly centered on clip boundary
          top: TimelineContainer.rulerHeight +
              TimelineContainer.trackSpacing +
              (TimelineContainer.clipHeight / 2) -
              12,
          child: GestureDetector(
            onTap: () => widget.onAddTransition(i),
            child: _CapCutTransitionButton(
              active: widget.transitions[i] != null,
            ),
          ),
        ),
      );
    }

    return widgets;
  }



  @override
  void initState() {
    super.initState();
    _scrollController = TimelineContainer.scrollController;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.onTimelineScroll == null ||
        !_scrollController.hasClients ||
        !mounted) return;

    if (widget.isPlaying) return;

    final maxTime = widget.durations.fold(0.0, (a, b) => a + b);
    final timePosition =
    (_scrollController.offset / TimelineContainer.pixelsPerSecond)
        .clamp(0.0, maxTime);

    widget.onTimelineScroll!(timePosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final totalVideoDuration =
    widget.durations.fold(0.0, (a, b) => a + b);

    final videoTimelineWidth =
        totalVideoDuration * TimelineContainer.pixelsPerSecond;

    final timelineWidth = videoTimelineWidth;

    final sidePadding = screenWidth / 2;

    return Container(
      color: const Color(0xFF0E0E0E),
      child: Stack(
        children: [
          // ===================== SCROLLABLE TIMELINE =====================
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: _isEffectDragging
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: SizedBox(
                width: timelineWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ================= BASE TIMELINE CONTENT =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeRuler(timelineWidth),
                        const SizedBox(height: TimelineContainer.trackSpacing),

                        /// VIDEO
                        VideoTimeline(
                          images: widget.images,
                          durations: widget.durations,
                          transitions: widget.transitions,
                          onAddTransition: widget.onAddTransition,
                          selectedIndex: widget.selectedIndex,
                          onSelect: widget.onSelect,
                          onReorder: widget.onReorder,
                          onDurationChange: widget.onDurationChange,
                          onDurationDragStart: widget.onDurationDragStart,
                          onDurationDragEnd: widget.onDurationDragEnd,
                        ),

                        /// EFFECT
                        if (widget.effectClips.isNotEmpty) ...[
                          const SizedBox(height: TimelineContainer.trackSpacing),
                          EffectTimeline(
                            effects: widget.effectClips,
                            totalDuration: widget.durations.fold(0.0, (a, b) => a + b),
                            onSelect: widget.onEffectSelect,
                            onMove: widget.onEffectMove,
                            onDragStart: () {
                              setState(() => _isEffectDragging = true);
                            },
                            onDragEnd: () {
                              setState(() => _isEffectDragging = false);
                            },
                          ),


                        ],

                        /// TEXT
                        if (widget.textClips.isNotEmpty) ...[
                          const SizedBox(height: TimelineContainer.trackSpacing),
                          TextTimeline(
                            textClips: widget.textClips,
                            selectedTextClip: widget.selectedTextClip,
                            timelineWidth: timelineWidth,
                            totalDuration:
                            widget.durations.fold(0.0, (a, b) => a + b),
                            onTextClipSelect: widget.onTextClipSelect,
                            onTextClipTrim: widget.onTextClipTrim,
                            onTextClipMove: widget.onTextClipMove,
                          ),
                        ],

                        /// AUDIO
                        if (widget.audioClip != null) ...[
                          const SizedBox(height: TimelineContainer.trackSpacing),
                          AudioTimeline(
                            audioClip: widget.audioClip!,
                            onAudioClipChanged: widget.onAudioClipChanged,
                            onDurationDragStart: widget.onDurationDragStart,
                            onDurationDragEnd: widget.onDurationDragEnd,
                            scrollController: _scrollController,
                          ),
                        ],
                      ],
                    ),

                    // ================= TRANSITION BUTTONS (SCROLL WITH CLIPS) =================
                    ..._buildScrollableTransitionButtons(),
                  ],
                ),
              ),

            ),
          ),




          // ===================== PLAYHEAD =====================
          Positioned(
            left: screenWidth / 2 - 1,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(width: 2, color: Colors.white),
            ),
          ),

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

  Widget _buildTimeRuler(double width) {
    final seconds = (width / TimelineContainer.pixelsPerSecond).ceil();

    return SizedBox(
      height: TimelineContainer.rulerHeight,
      width: width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: seconds + 1,
        itemBuilder: (context, i) {
          return SizedBox(
            width: TimelineContainer.pixelsPerSecond,
            child: Row(
              children: [
                Container(width: 1, height: 8, color: Colors.white38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatTime(i.toDouble()),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.clip,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



class _CapCutTransitionButton extends StatelessWidget {
  final bool active;

  const _CapCutTransitionButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? Colors.orangeAccent : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        active ? Icons.auto_awesome : Icons.add,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}
