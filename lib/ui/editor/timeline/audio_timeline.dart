import 'dart:async';

import 'package:reelspark/ui/editor/editor.dart';


/// Audio timeline track widget
///
/// Displays audio clip with:
/// - Waveform representation
/// - Trim handles with continuous auto-scroll
/// - Duration display
class AudioTimeline extends StatefulWidget {
  final AudioClip audioClip;
  final Function(AudioClip)? onAudioClipChanged;
  final ScrollController scrollController;
  final VoidCallback? onDurationDragStart; // ✅ ADD
  final VoidCallback? onDurationDragEnd;

  const AudioTimeline({
    super.key,
    required this.audioClip,
    required this.scrollController,
    this.onAudioClipChanged,
    this.onDurationDragStart,
    this.onDurationDragEnd,
  });

  @override
  State<AudioTimeline> createState() => _AudioTimelineState();
}

class _AudioTimelineState extends State<AudioTimeline> {
  int _audioTrimEdge = 0; // -1 = left, 1 = right, 0 = none
  double _audioTrimAccumulatedDx = 0;
  bool _isAudioSelected = false;
  bool _isAtMinDuration = false;

  Timer? _autoScrollTimer;
  double _currentTrimDragX = 0;
  bool _isAudioTrimming = false;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startContinuousAutoScroll(BuildContext context) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isAudioTrimming || !widget.scrollController.hasClients) {
        _stopContinuousAutoScroll();
        return;
      }
      _performAutoScroll(context);
    });
  }

  void _stopContinuousAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _performAutoScroll(BuildContext context) {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const edgeThreshold = 80.0;
    const fastScrollSpeed = 12.0;

    final position = widget.scrollController.position;
    final currentOffset = position.pixels;
    final maxOffset = position.maxScrollExtent;

    if (_currentTrimDragX < edgeThreshold && currentOffset > 0) {
      final scrollAmount = fastScrollSpeed * (1 - _currentTrimDragX / edgeThreshold);
      widget.scrollController.jumpTo((currentOffset - scrollAmount).clamp(0.0, maxOffset));
    } else if (_currentTrimDragX > screenWidth - edgeThreshold && currentOffset < maxOffset) {
      final edgeDistance = screenWidth - _currentTrimDragX;
      final scrollAmount = fastScrollSpeed * (1 - edgeDistance / edgeThreshold);
      widget.scrollController.jumpTo((currentOffset + scrollAmount).clamp(0.0, maxOffset));
    }
  }

  void _handleAudioTrimDrag({
    required double deltaDx,
    required bool isLeftHandle,
  }) {
    if (widget.onAudioClipChanged == null) return;

    _audioTrimAccumulatedDx += deltaDx;
    final deltaSeconds = _audioTrimAccumulatedDx / TimelineContainer.pixelsPerSecond;

    if (deltaSeconds.abs() < 0.02) return;
    _audioTrimAccumulatedDx = 0;

    final audioClip = widget.audioClip;
    final currentDuration = audioClip.duration;
    AudioClip updatedClip;

    if (isLeftHandle) {
      final requestedTrimStart = audioClip.trimStart + deltaSeconds;
      final newTrimStart = requestedTrimStart.clamp(
        0.0,
        audioClip.trimEnd - AudioClip.minDuration,
      );

      // Check if we're trying to go below minimum duration
      final requestedDuration = audioClip.trimEnd - requestedTrimStart;
      final atMinDuration = (currentDuration <= AudioClip.minDuration && deltaSeconds > 0) ||
                            (requestedDuration < AudioClip.minDuration && deltaSeconds > 0);
      if (_isAtMinDuration != atMinDuration) {
        setState(() {
          _isAtMinDuration = atMinDuration;
        });
      }

      updatedClip = audioClip.copyWith(trimStart: newTrimStart);
    } else {
      final requestedTrimEnd = audioClip.trimEnd + deltaSeconds;
      final newTrimEnd = requestedTrimEnd.clamp(
        audioClip.trimStart + AudioClip.minDuration,
        audioClip.originalDuration,
      );

      // Check if we're trying to go below minimum duration
      final requestedDuration = requestedTrimEnd - audioClip.trimStart;
      final atMinDuration = (currentDuration <= AudioClip.minDuration && deltaSeconds < 0) ||
                            (requestedDuration < AudioClip.minDuration && deltaSeconds < 0);
      if (_isAtMinDuration != atMinDuration) {
        setState(() {
          _isAtMinDuration = atMinDuration;
        });
      }

      updatedClip = audioClip.copyWith(trimEnd: newTrimEnd);
    }

    widget.onAudioClipChanged!(updatedClip);
  }

  @override
  Widget build(BuildContext context) {
    final audioWidth = widget.audioClip.duration * TimelineContainer.pixelsPerSecond;
    final isSelected = _isAudioSelected;
    final isTrimming = _audioTrimEdge != 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAudioSelected = !_isAudioSelected;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: TimelineContainer.audioTrackHeight,
        width: audioWidth > 0 ? audioWidth : 100,
        margin: EdgeInsets.only(left: widget.audioClip.startTime * TimelineContainer.pixelsPerSecond),
        decoration: BoxDecoration(
          color: _isAtMinDuration
              ? Colors.red.withValues(alpha: 0.7)
              : Colors.green.withValues(alpha: isSelected ? 0.4 : 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isAtMinDuration
                ? Colors.red
                : (isSelected
                    ? Colors.greenAccent
                    : Colors.greenAccent.withValues(alpha: 0.6)),
            width: _isAtMinDuration ? 2.5 : (isSelected ? 2.0 : 1.5),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.music_note,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.audioClip.fileName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
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
                                  '${widget.audioClip.duration.toStringAsFixed(1)}s',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isAtMinDuration)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'MIN: ${AudioClip.minDuration.toStringAsFixed(1)}s',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),

            // LEFT TRIM HANDLE
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    widget.onDurationDragStart?.call(); // ✅ UNDO START

                    setState(() {
                      _audioTrimEdge = -1;
                      _audioTrimAccumulatedDx = 0;
                      _isAudioTrimming = true;
                      _currentTrimDragX = details.globalPosition.dx;
                    });

                    _startContinuousAutoScroll(context);
                  },

                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _currentTrimDragX = details.globalPosition.dx;
                    });
                    _handleAudioTrimDrag(
                      deltaDx: details.delta.dx,
                      isLeftHandle: true,
                    );
                  },
                  onHorizontalDragEnd: (_) {
                    widget.onDurationDragEnd?.call(); // ✅ UNDO COMMIT

                    setState(() {
                      _audioTrimEdge = 0;
                      _isAudioTrimming = false;
                      _isAtMinDuration = false;
                    });

                    _stopContinuousAutoScroll();
                  },

                  child: _buildAudioTrimHandle(
                    isLeft: true,
                    isActive: isTrimming && _audioTrimEdge == -1,
                  ),
                ),
              ),

            // RIGHT TRIM HANDLE
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onHorizontalDragStart: (details) {
                    widget.onDurationDragStart?.call();
                    setState(() {
                      _audioTrimEdge = 1;
                      _audioTrimAccumulatedDx = 0;
                      _isAudioTrimming = true;
                      _currentTrimDragX = details.globalPosition.dx;
                    });
                    _startContinuousAutoScroll(context);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _currentTrimDragX = details.globalPosition.dx;
                    });
                    _handleAudioTrimDrag(
                      deltaDx: details.delta.dx,
                      isLeftHandle: false,
                    );
                  },
                  onHorizontalDragEnd: (_) {
                    widget.onDurationDragEnd?.call(); // ✅
                    setState(() {
                      _audioTrimEdge = 0;
                      _isAudioTrimming = false;
                      _isAtMinDuration = false;
                    });
                    _stopContinuousAutoScroll();
                  },
                  child: _buildAudioTrimHandle(
                    isLeft: false,
                    isActive: isTrimming && _audioTrimEdge == 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioTrimHandle({required bool isLeft, required bool isActive}) {
    // Show red when at minimum duration and trying to decrease
    final isAtLimit = _isAtMinDuration && isActive;

    return Container(
      width: TimelineContainer.handleWidth,
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red : (isActive ? Colors.greenAccent : Colors.green),
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(6) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(6),
        ),
      ),
      child: Center(
        child: isAtLimit
            ? Icon(
                Icons.lock,
                size: 12,
                color: Colors.white,
              )
            : Container(
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
}
