import 'package:flutter/scheduler.dart';

import '../templates.dart';
import '../services/timeline_controller.dart';
import '../services/animation_state.dart';
import '../services/timeline_clock.dart';
import '../widgets/live_preview_shared.dart';
import 'music_picker_screen.dart';


/// Fast, in-app preview (no FFmpeg) that shows how the template will look
/// with selected images + effect + transition.
///
/// CRITICAL: Uses [TimelineController] for timing calculations to ensure
/// frame-perfect sync with rendered video.
class TemplateLivePreviewScreen extends StatefulWidget {
  final VideoTemplate template;
  final List<File> images;

  const TemplateLivePreviewScreen({
    super.key,
    required this.template,
    required this.images,
  });

  @override
  State<TemplateLivePreviewScreen> createState() => _TemplateLivePreviewScreenState();
}

class _TemplateLivePreviewScreenState extends State<TemplateLivePreviewScreen>
    with SingleTickerProviderStateMixin {
  late TimelineController _timeline;
  late TimelineClock _clock;

  // Fixed-step ticker (for driving the clock), not for animations.
  late final Ticker _ticker;
  Duration? _lastTick;
  double _accumulatorSec = 0.0;

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audio = AudioPlayer();

  late List<File> _images;
  String? _musicOverride;

  bool _isPaused = false;
  bool _isMusicPlaying = false;

  /// Current deterministic animation state for this preview frame.
  late AnimationState _state;

  // Keep a stable listener reference so dispose can remove it.
  late final VoidCallback _clockListener;

  @override
  void initState() {
    super.initState();

    _images = List<File>.from(widget.images);

    // Use TimelineController for consistent timing with render
    _timeline = TimelineController.fromTemplate(widget.template);

    _clock = TimelineClock(
      fps: TimelineController.fps,
      totalDurationSeconds: _timeline.totalDuration,
      loop: true,
      initialTimeSeconds: 0.0,
    );

    _state = AnimationState.from(
      timelineController: _timeline,
      timeSeconds: 0.0,
    );

    _clockListener = () {
      _state = AnimationState.from(
        timelineController: _timeline,
        timeSeconds: _clock.timeSeconds,
      );
      if (mounted) setState(() {});
    };
    _clock.addListener(_clockListener);

    _ticker = createTicker(_onTick)..start();

    // ✅ Audio completion → restart if video still running
    _audio.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          !_isPaused &&
          _isMusicPlaying) {
        _audio.seek(Duration.zero);
        _audio.play();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _precacheNearby();
      await _initAudio(); // ✅ ONLY init (play happens inside)
    });
  }

  void _onTick(Duration now) {
    if (_isPaused) {
      _lastTick = now;
      return;
    }

    final last = _lastTick;
    _lastTick = now;
    if (last == null) return;

    // Accumulate real elapsed time, but step the simulation ONLY in fixed increments.
    final dtSec = (now - last).inMicroseconds / 1e6;
    if (dtSec <= 0) return;

    _accumulatorSec += dtSec;

    // Step exactly 1/fps. Cap steps per tick to avoid spiral of death.
    final stepDt = _clock.frameDurationSeconds;
    var steps = 0;
    const maxStepsPerTick = 5;
    while (_accumulatorSec >= stepDt && steps < maxStepsPerTick) {
      _accumulatorSec -= stepDt;
      _clock.step(1);
      steps++;

      // When the clock loops, reset audio (audio must not drive visuals)
      if (_clock.frameIndex == 0 && _isMusicPlaying) {
        _audio.seek(Duration.zero);
        _audio.play();
      }
    }

    // If we capped, drop remainder to keep UI responsive (still deterministic frame deltas).
    if (steps >= maxStepsPerTick) {
      _accumulatorSec = 0.0;
    }
  }

  Future<void> _initAudio() async {
    final src = _musicOverride ?? widget.template.music;
    debugPrint('Attempting to load audio: $src');

    try {

      bool loaded = false;

      if (src.startsWith('assets/')) {
        await _audio.setAsset(src);
        loaded = true;
      } else {
        final f = File(src);
        if (await f.exists()) {
          await _audio.setFilePath(f.path);
          loaded = true;
        } else {
          await _audio.setUrl(src);
          loaded = true;
        }
      }

      if (!loaded) return;

      await _audio.setLoopMode(LoopMode.off);

      // ✅ PLAY ONLY AFTER SOURCE IS READY
      await _audio.play();

      if (mounted) {
        setState(() {
          _isMusicPlaying = true;
        });
      }

      debugPrint('Audio started successfully');
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
  }



  /// Calculate elapsed time up to current index + progress within current image.
  /// Uses _currentTime which is frame-locked via TimelineController.


  /// Seek audio to match current clock time.
  Future<void> _syncAudioToClock() async {
    try {
      final elapsed = Duration(milliseconds: (_clock.timeSeconds * 1000).round());
      final audioDuration = _audio.duration ?? Duration.zero;
      if (audioDuration <= Duration.zero) return;

      final seekPosition = elapsed.inMilliseconds >= audioDuration.inMilliseconds
          ? Duration(milliseconds: elapsed.inMilliseconds % audioDuration.inMilliseconds)
          : elapsed;

      await _audio.seek(seekPosition);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.removeListener(_clockListener);
    _audio.stop();
    _audio.dispose();
    super.dispose();
  }

  void _precacheNearby() {
    if (!mounted || _images.isEmpty) return;

    final idx = _state.timeline.stepIndex % _images.length;
    final current = _images[idx];
    final next = _images[(idx + 1) % _images.length];

    for (final f in [current, next]) {
      final provider = ResizeImage(
        FileImage(f),
        width: 720,
        height: 1280,
      );
      precacheImage(provider, context);
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        if (_isMusicPlaying) {
          _audio.pause();
        }
      } else {
        if (_isMusicPlaying) {
          _audio.play();
        }
      }
    });
  }

  /// Helper method to check if current time is between sticker/text start and end times.
  ///
  /// Uses _currentTime which is calculated from TimelineController for frame-perfect sync.
  bool _isBetween(int start, int end) {
    final t = _state.timeSeconds;
    return t >= start && t <= end;
  }

  /// Build sticker widget (supports both images and videos)
  Widget _buildStickerWidget(String asset, String position) {
    final isVideo = asset.endsWith('.mp4') || asset.endsWith('.webm');

    Widget content;
    if (isVideo) {
      // For video stickers, use a stateful wrapper
      content = _VideoStickerPlayer(asset: asset);
    } else {
      // For image stickers
      content = Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) {
          debugPrint('Error loading sticker: $asset - $error');
          return Container(); // Hide if asset not found
        },
      );
    }

    // Apply positioning - use smaller sizes so photos are visible
    double heightFactor;
    double widthFactor;
    Alignment alignment;
    EdgeInsets padding;

    switch (position) {
      case 'top':
        heightFactor = 0.20; // 20% of screen height
        widthFactor = 0.6;   // 60% of screen width
        alignment = Alignment.topCenter;
        padding = const EdgeInsets.only(top: 40);
        break;
      case 'bottom':
        heightFactor = 0.20; // 20% of screen height
        widthFactor = 0.6;   // 60% of screen width
        alignment = Alignment.bottomCenter;
        padding = const EdgeInsets.only(bottom: 40);
        break;
      case 'full':
        heightFactor = 0.5;  // 50% of screen
        widthFactor = 0.8;   // 80% of screen width
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
        break;
      default:
        heightFactor = 0.3;
        widthFactor = 0.7;
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
    }

    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          widthFactor: widthFactor,
          child: content,
        ),
      ),
    );
  }

  /// Build text widget with styling and animation using TimelineController.
  ///
  /// CRITICAL: Uses [TimelineController.getTextAnimationState] for frame-perfect
  /// sync with rendered video.

  Future<void> _replaceImageAt(int index) async {
    if (_images.isEmpty) return;
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (!mounted) return;

    setState(() {
      _images[index] = File(x.path);
    });

    _precacheNearby();
  }

  void _removeImageAt(int index) {
    if (_images.isEmpty || index < 0 || index >= _images.length) return;

    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) {
        // Keep clock running, just show empty.
        return;
      }

      // Clamp clock to valid index range if needed.
      // We keep time as-is; image selection uses modulo.
    });

    _precacheNearby();
  }

  Future<void> _addImageToSlot(int slotIndex) async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (!mounted) return;

    setState(() {
      if (slotIndex >= _images.length) {
        _images.add(File(x.path));
      } else {
        _images.insert(slotIndex, File(x.path));
      }
    });

    _precacheNearby();
  }



  Future<void> _openMusicPicker() async {
    // Pause current music while picking
    try {
      await _audio.pause();
    } catch (_) {}

    final selection = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPickerScreen(
          templateMusic: widget.template.music,
          selected: _musicOverride,
        ),
      ),
    );

    if (!mounted || selection == null) {
      // Resume music if no selection made
      if (_isMusicPlaying) {
        try {
          await _audio.play();
        } catch (_) {}
      }
      return;
    }

    if (selection == '__reset__') {
      setState(() => _musicOverride = null);
    } else {
      setState(() => _musicOverride = selection);
    }

    // Reload and auto-play the new music
    await _initAudio();
    try {
      await _initAudio();
      debugPrint('New audio playback started');
    } catch (e) {
      debugPrint('Error starting new audio playback: $e');
    }
  }

    ColorFilter? _colorFilterForEffect(String effect) {
    switch (effect) {
      case 'bw':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'warm':
        return const ColorFilter.mode(Color(0x22FF7A00), BlendMode.overlay);
      case 'cool':
        return const ColorFilter.mode(Color(0x2200A3FF), BlendMode.overlay);
      case 'cinematic':
        return const ColorFilter.mode(Color(0x11000000), BlendMode.overlay);
      default:
        return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final frame = _state.timeline;

    final step = frame.step;
    final nextStep = frame.nextStep;

    final filter = _colorFilterForEffect(step.effect);

    final fromImg = _images.isEmpty ? null : _images[frame.stepIndex % _images.length];
    final toImg = _images.isEmpty ? null : _images[frame.nextStepIndex % _images.length];

    Widget fromLayer = fromImg == null
        ? Container(color: Colors.grey.shade900)
        : TemplateMotion(
            motion: step.motion,
            progress: frame.motionProgress,
            child: Image(
              image: ResizeImage(FileImage(fromImg), width: 720, height: 1280),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          );

    Widget toLayer = toImg == null
        ? Container(color: Colors.grey.shade900)
        : TemplateMotion(
            motion: nextStep.motion,
            progress: frame.transitionProgress,
            child: Image(
              image: ResizeImage(FileImage(toImg), width: 720, height: 1280),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          );

    final transition = frame.isInTransition ? frame.transitionType : 'cut';
    final transitionT = frame.isInTransition ? frame.transitionProgress : 0.0;

    Widget preview = DualTransitionFrame(
      transition: transition,
      t: transitionT,
      fromChild: fromLayer,
      toChild: toLayer,
    );

    if (filter != null) {
      preview = ColorFiltered(colorFilter: filter, child: preview);
    }

    final canGenerate = _images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Preview', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: !canGenerate
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TemplateRenderingScreen(
                                template: widget.template,
                                images: _images,
                                musicOverride: _musicOverride,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black12,
                    disabledForegroundColor: Colors.black38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    elevation: 0,
                  ),
                  child: const Text('Generate', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          preview,
                          if (widget.template.effect == 'vignette')
                            Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [Colors.transparent, Color(0xAA000000)],
                                  radius: 1.1,
                                ),
                              ),
                            ),
                          for (final s in widget.template.stickers)
                            if (_isBetween(s.start, s.end))
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _buildStickerWidget(s.asset, s.position),
                                ),
                              ),
                          for (final t in widget.template.texts)
                            if (_isBetween(t.start, t.end))
                              Positioned(
                                top: t.position == 'top' ? 60 : null,
                                bottom: t.position == 'bottom' ? 60 : null,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Center(child: _buildTextWidgetDeterministic(t)),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _PreviewBottomPanel(
              images: _images,
              currentIndex: frame.stepIndex,
              isPaused: _isPaused,
              // We can’t pass AnimationController anymore; use progress.
              timelineProgress: _clock.timeSeconds / _clock.totalDurationSeconds,
              totalSlots: widget.template.resolvedSlots,
              onTogglePause: _togglePause,
              onSeek: (val) async {
                _clock.seekProgress(val);
                await _syncAudioToClock();
              },
              onTapThumb: _replaceImageAt,
              onLongPressThumb: (i) {
                // Seek to start of step
                final t0 = _timeline.getStepStartTime(i);
                _clock.seekSeconds(t0);
              },
              onRemoveThumb: _removeImageAt,
              onAddToSlot: _addImageToSlot,
              onOpenMusic: _openMusicPicker,
            ),
          ],
        ),
      ),
    );
  }

  /// Deterministic text widget based on time.
  Widget _buildTextWidgetDeterministic(TemplateText text) {
    final anim = AnimationState.text(_timeline, text, _state.timeSeconds);
    final base = _buildTextStyleOnly(text);

    return Transform.scale(
      scale: anim.scale,
      child: Opacity(opacity: anim.opacity, child: base),
    );
  }

  /// Returns styling only. NO animation.
  Widget _buildTextStyleOnly(TemplateText text) {
    TextStyle style;

    switch (text.style) {
      case 'bold_white':
        style = const TextStyle(
          color: Colors.white,
          fontSize: 36, // Reduced from 48
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 8,
              color: Colors.black54,
            ),
          ],
        );
        break;
      case 'gold':
        style = TextStyle(
          color: const Color(0xFFFFD700),
          fontSize: 32, // Reduced from 42
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ],
        );
        break;
      case 'neon':
        style = const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 42, // Reduced from 56
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 20,
              color: Color(0xFF0CE781),
            ),
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 40,
              color: Color(0xFF00FF88),
            ),
          ],
        );
        break;
      default:
        style = const TextStyle(
          color: Colors.white,
          fontSize: 28, // Reduced from 36
          fontWeight: FontWeight.w700,
        );
    }

    return Text(
      text.text,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class _PreviewBottomPanel extends StatelessWidget {
  final List<File> images;
  final int currentIndex;
  final bool isPaused;
  final double timelineProgress;
  final int totalSlots;

  final VoidCallback onTogglePause;
  final ValueChanged<double> onSeek;
  final ValueChanged<int> onTapThumb;
  final ValueChanged<int> onLongPressThumb;
  final ValueChanged<int> onRemoveThumb;
  final ValueChanged<int> onAddToSlot;

  final VoidCallback onOpenMusic;

  const _PreviewBottomPanel({
    required this.images,
    required this.currentIndex,
    required this.isPaused,
    required this.timelineProgress,
    required this.totalSlots,
    required this.onTogglePause,
    required this.onSeek,
    required this.onTapThumb,
    required this.onLongPressThumb,
    required this.onRemoveThumb,
    required this.onAddToSlot,
    required this.onOpenMusic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: isPaused ? 'Play' : 'Pause',
                  onPressed: onTogglePause,
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  color: Colors.black87,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: const Color(0xFF16A34A),
                      inactiveTrackColor: Colors.black12,
                      thumbColor: const Color(0xFF16A34A),
                    ),
                    child: Slider(
                      value: timelineProgress,
                      onChanged: onSeek,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Add photo',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${images.length}/$totalSlots',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: totalSlots,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final hasImage = i < images.length;
                  final f = hasImage ? images[i] : null;
                  final selected = hasImage && i == currentIndex;

                  if (!hasImage) {
                    // Empty slot - show add button
                    return GestureDetector(
                      onTap: () => onAddToSlot(i),
                      child: Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black12,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filled slot with image
                  return GestureDetector(
                    onTap: () => onTapThumb(i),
                    onLongPress: () => onLongPressThumb(i),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image(
                            image: ResizeImage(FileImage(f!), width: 220, height: 360),
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? const Color(0xFF16A34A) : Colors.black26,
                                width: selected ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                        // Pencil icon in top-right corner
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _ThumbIconButton(
                            icon: Icons.edit,
                            onPressed: () => onTapThumb(i),
                          ),
                        ),
                        // Slot number badge
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child:
                            Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const IconButton(
                  tooltip: 'Photos',
                  onPressed: null,
                  icon: Icon(Icons.photo_outlined),
                  color: Colors.black54,
                ),
                IconButton(
                  tooltip: 'Change Music',
                  onPressed: onOpenMusic,
                  icon: const Icon(Icons.music_note_outlined),
                  color: Colors.black54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//
// // --- New: modern editor sheet (white card) ---
//
// class _PreviewEditorSheet extends StatefulWidget {
//   final int initialTabIndex;
//   final ValueChanged<int> onTabPersist;
//
//   final List<File> images;
//   final int currentIndex;
//   final ValueChanged<int> onTapThumb;
//   final Future<void> Function(int index) onReplace;
//   final void Function(int index) onRemove;
//   final Future<void> Function() onPickMultiReplaceAll;
//
//   final String musicLabel;
//   final Future<void> Function() onPickMusic;
//   final Future<void> Function()? onResetMusic;
//
//   const _PreviewEditorSheet({
//     required this.initialTabIndex,
//     required this.onTabPersist,
//     required this.images,
//     required this.currentIndex,
//     required this.onTapThumb,
//     required this.onReplace,
//     required this.onRemove,
//     required this.onPickMultiReplaceAll,
//     required this.musicLabel,
//     required this.onPickMusic,
//     required this.onResetMusic,
//   });
//
//   @override
//   State<_PreviewEditorSheet> createState() => _PreviewEditorSheetState();
// }
//
// class _PreviewEditorSheetState extends State<_PreviewEditorSheet> {
//   late int _tabIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabIndex = widget.initialTabIndex;
//   }
//
//   void _setTab(int i) {
//     if (i == _tabIndex) return;
//     setState(() => _tabIndex = i);
//     widget.onTabPersist(i);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.transparent,
//       ),
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.48,
//         minChildSize: 0.30,
//         maxChildSize: 0.86,
//         builder: (context, controller) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
//             ),
//             child: ListView(
//               controller: controller,
//               padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
//               children: [
//                 Center(
//                   child: Container(
//                     width: 46,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.black12,
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         'Edit',
//                         style: TextStyle(
//                           color: Colors.black87,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       tooltip: 'Close',
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.close_rounded),
//                     ),
//                   ],
//                 },
//                 const SizedBox(height: 8),
//
//                 _SegmentedTabs(
//                   index: _tabIndex,
//                   onChanged: _setTab,
//                   labels: const ['Photos', 'Music'],
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 220),
//                   switchInCurve: Curves.easeOutCubic,
//                   switchOutCurve: Curves.easeInCubic,
//                   transitionBuilder: (child, anim) {
//                     final slide = Tween<Offset>(
//                       begin: const Offset(0, 0.03),
//                       end: Offset.zero,
//                     ).animate(anim);
//                     return FadeTransition(
//                       opacity: anim,
//                       child: SlideTransition(position: slide, child: child),
//                     );
//                   },
//                   child: _tabIndex == 0
//                       ? _PhotosTab(
//                           key: const ValueKey('photos_tab'),
//                           images: widget.images,
//                           currentIndex: widget.currentIndex,
//                           onTapThumb: widget.onTapThumb,
//                           onReplace: widget.onReplace,
//                           onRemove: widget.onRemove,
//                           onPickMultiReplaceAll: widget.onPickMultiReplaceAll,
//                         )
//                       : _MusicTab(
//                           key: const ValueKey('music_tab'),
//                           musicLabel: widget.musicLabel,
//                           onPickMusic: widget.onPickMusic,
//                           onResetMusic: widget.onResetMusic,
//                         ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _SegmentedTabs extends StatelessWidget {
//   final int index;
//   final ValueChanged<int> onChanged;
//   final List<String> labels;
//
//   const _SegmentedTabs({
//     required this.index,
//     required this.onChanged,
//     required this.labels,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F4F7),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.black12),
//       ),
//       child: Row(
//         children: List.generate(labels.length, (i) {
//           final selected = i == index;
//           return Expanded(
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onTap: () => onChanged(i),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 curve: Curves.easeOutCubic,
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 decoration: BoxDecoration(
//                   color: selected ? Colors.white : Colors.transparent,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: selected
//                       ? const [
//                           BoxShadow(
//                             color: Color(0x14000000),
//                             blurRadius: 10,
//                             offset: Offset(0, 4),
//                           ),
//                         ]
//                       : null,
//                 ),
//                 child: Center(
//                   child: Text(
//                     labels[i],
//                     style: TextStyle(
//                       fontWeight: FontWeight.w800,
//                       color: selected ? Colors.black87 : Colors.black54,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }
//
// class _PhotosTab extends StatelessWidget {
//   final List<File> images;
//   final int currentIndex;
//   final ValueChanged<int> onTapThumb;
//   final Future<void> Function(int index) onReplace;
//   final void Function(int index) onRemove;
//   final Future<void> Function() onPickMultiReplaceAll;
//
//   const _PhotosTab({
//     super.key,
//     required this.images,
//     required this.currentIndex,
//     required this.onTapThumb,
//     required this.onReplace,
//     required this.onRemove,
//     required this.onPickMultiReplaceAll,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Expanded(
//               child: Text(
//                 'Photos',
//                 style: TextStyle(fontWeight: FontWeight.w800),
//               ),
//             ),
//             OutlinedButton.icon(
//               onPressed: onPickMultiReplaceAll,
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.black12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               icon: const Icon(Icons.photo_library_outlined, size: 18),
//               label: const Text('Replace all'),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 100,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: images.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 10),
//             itemBuilder: (context, i) {
//               final img = images[i];
//               final selected = i == currentIndex;
//               return RepaintBoundary(
//                 child: GestureDetector(
//                   onTap: () => onReplace(i),
//                   child: Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(14),
//                         child: Image(
//                           image: ResizeImage(FileImage(img), width: 220, height: 360),
//                           width: 70,
//                           height: 100,
//                           fit: BoxFit.cover,
//                           filterQuality: FilterQuality.medium,
//                         ),
//                       ),
//                       Positioned.fill(
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(
//                               color: selected ? const Color(0xFF16A34A) : Colors.black12,
//                               width: selected ? 2 : 1,
//                             ),
//                           ),
//                         ),
//                       ),
//                       // Pencil icon in top-right corner
//                       Positioned(
//                         top: 4,
//                         right: 4,
//                         child: _ThumbIconButton(
//                           icon: Icons.edit,
//                           onPressed: () => onReplace(i),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Tip: Tap the main preview or a photo below to replace it.',
//           style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
//         ),
//       ],
//     );
//   }
// }
//
// class _MusicTab extends StatelessWidget {
//   final String musicLabel;
//   final Future<void> Function() onPickMusic;
//   final Future<void> Function()? onResetMusic;
//
//   const _MusicTab({
//     super.key,
//     required this.musicLabel,
//     required this.onPickMusic,
//     required this.onResetMusic,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Music',
//           style: TextStyle(fontWeight: FontWeight.w800),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF2F4F7),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.black12),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.music_note, color: Colors.black54),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   musicLabel,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: onResetMusic,
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: const Color(0xFF0F172A),
//                   side: const BorderSide(color: Colors.black12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 icon: const Icon(Icons.restart_alt_rounded, size: 20),
//                 label: const Text(
//                   'Reset',
//                   style: TextStyle(fontWeight: FontWeight.w800),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: onPickMusic,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF16A34A),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 icon: const Icon(Icons.library_music_rounded, size: 20),
//                 label: const Text(
//                   'Choose',
//                   style: TextStyle(fontWeight: FontWeight.w800),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Text(
//           'Choose music from your device or bundled tracks.',
//           style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
//         ),
//       ],
//     );
//   }
// }

// NOTE: _MusicPickerSheet remains below.
// It is now unused but kept for compatibility; can be removed later.

class _MusicPickerSheet extends StatefulWidget {
  final String templateMusic;
  final String? selected;

  const _MusicPickerSheet({
    required this.templateMusic,
    required this.selected,
  });

  @override
  State<_MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<_MusicPickerSheet> {
  late Future<List<String>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    _assetsFuture = _loadMusicAssets();
  }

  Future<void> _pickFromDevice() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: false,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
    );

    final path = res?.files.single.path;
    if (path == null) return;
    if (!mounted) return;

    Navigator.pop(context, path);
  }

  Future<List<String>> _loadMusicAssets() async {
    final raw = await rootBundle.loadString('AssetManifest.json');
    return _parseManifest(raw);
  }

  List<String> _parseManifest(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final keys = decoded.keys
          .where((k) => k.startsWith('assets/templates/music/'))
          .toList(growable: false);
      keys.sort();
      if (keys.contains(widget.templateMusic)) {
        keys.remove(widget.templateMusic);
        keys.insert(0, widget.templateMusic);
      }
      if (keys.isEmpty) return <String>[widget.templateMusic];
      return keys;
    } catch (_) {
      return <String>[widget.templateMusic];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select music',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickFromDevice,
                  child: const Text('Device'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, '__reset__'),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FutureBuilder<List<String>>(
              future: _assetsFuture,
              builder: (context, snap) {
                final items = snap.data ?? <String>[];
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.black12, height: 1),
                    itemBuilder: (context, i) {
                      final path = items[i];
                      final selected = path == (widget.selected ?? widget.templateMusic);
                      final name = path.split('/').last;
                      return ListTile(
                        onTap: () => Navigator.pop(context, path),
                        dense: true,
                        leading: Icon(
                          selected ? Icons.check_circle : Icons.music_note,
                          color: selected ? const Color(0xFF16A34A) : Colors.black54,
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.black87)),
                        subtitle: Text(path, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ThumbIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}
/// Stateful video sticker player widget
class _VideoStickerPlayer extends StatefulWidget {
  final String asset;

  const _VideoStickerPlayer({required this.asset});

  @override
  State<_VideoStickerPlayer> createState() => _VideoStickerPlayerState();
}

class _VideoStickerPlayerState extends State<_VideoStickerPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      _controller = VideoPlayerController.asset(widget.asset);
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video sticker: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(); // Empty while loading
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
