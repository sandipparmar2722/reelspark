import 'dart:async';

import 'package:reelspark/ui/editor/editor.dart';
import 'package:reelspark/ui/editor/transition/transition_picker.dart';

import '../../models/effect_clip.dart';
/// Main video editor screen with CapCut-inspired UI design.
///
/// Structure:
/// 1. Top Bar: Back, Resolution, Export
/// 2. Preview Area: 9:16 aspect ratio with play button overlay
/// 3. Timeline: Horizontal scrollable clip thumbnails
/// 4. Bottom Bar: Audio, Text, Effects tools
class EditorScreen extends StatefulWidget {
  final List<File> images;

  const EditorScreen({super.key, required this.images});

  @override
  State<EditorScreen> createState() => _EditorScreenState();


}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {

  final List<EditorSnapshot> _undoStack = [];
  final List<EditorSnapshot> _redoStack = [];
  bool _isDraggingDuration = false;
  EditorSnapshot? _dragStartSnapshot;
  late List<ClipTransition?> transitions;



  // ============================================================================
  // STATE VARIABLES
  // ============================================================================


  List<EffectClip> _effectClips = [];
  EffectClip? _selectedEffectClip;




  double mediaDuration = 5.0; // image/video duration (seconds)



  String? audioPath;
  double audioTrimEnd = 0.0;

  // --- Audio Clip model ---
  AudioClip? _audioClip;

  // === SINGLE SOURCE OF TRUTH FOR PLAYBACK ===
  double _currentPlayTime = 0.0;
  Timer? _playbackTicker;
  bool _isProgrammaticScroll = false;
  bool _isAudioReady = false;

  // --- Transition & Preview ---
  TransitionType transitionType = TransitionType.fade;
  late List<File> images;
  late List<double> durations;
  int selectedIndex = 0;
  int _currentPreviewIndex = 0;

  // --- Timers & Flags ---
  Timer? _previewTimer;
  bool isScrubbing = false;
  bool isExporting = false;
  bool isPlaying = false;

  // --- Animation Controller ---
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _zoomAnimation;

  // --- Text Overlay ---
  final TextEditingController textController = TextEditingController();
  List<TextClip> _textClips = [];
  TextClip? _selectedTextClip;

  // --- Music ---
  final AudioPlayer audioPlayer = AudioPlayer();

  // --- UI State ---
  EditorTool? _activeTool;
  bool _showTextInput = false;
  bool _showEffectsPanel = false;

  // --- Image Picker ---
  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  double _calculateStartTimeForIndex(int index) {
    double time = 0;
    for (int i = 0; i < index; i++) {
      time += durations[i];
    }
    return time;
  }

  double _calculateTotalDuration() {
    final videoDuration = durations.fold(0.0, (sum, d) => sum + d);
    final audioDuration = _audioClip?.duration ?? 0.0;
    final textDuration = _textClips.isNotEmpty
        ? _textClips.map((clip) => clip.endTime).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return [videoDuration, audioDuration, textDuration].reduce((a, b) => a > b ? a : b);
  }

  double _calculateTimelineOffsetForTime(double time) {
    const pixelsPerSecond = 60.0;
    final controller = TimelineContainer.scrollController;
    if (!controller.hasClients) return 0;
    final maxOffset = controller.position.maxScrollExtent;
    return (time * pixelsPerSecond).clamp(0.0, maxOffset);
  }

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();

    images = List.from(widget.images);
    durations = List.generate(images.length, (_) => 2.0);

    durations = List.generate(images.length, (_) => 2.0);

   // transitions count = images.length - 1
    transitions = List.generate(images.length - 1, (_) => null);


    _initMediaStore();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPreview());
  }



  // Calculate total video duration from image durations
  // Used for syncing audio and timeline

  double _calculateVideoDuration() {
    return durations.fold(0.0, (sum, d) => sum + d);
  }



  // Save current state for undo functionality
  // Call this method before any state-changing action





  void _onDurationDragStart() {
    if (_isDraggingDuration) return;

    _isDraggingDuration = true;
    _dragStartSnapshot = _createSnapshot();
  }
  void _onDurationDragEnd() {
    if (!_isDraggingDuration || _dragStartSnapshot == null) return;

    _undoStack.add(_dragStartSnapshot!);
    _redoStack.clear();

    _dragStartSnapshot = null;
    _isDraggingDuration = false;
  }


  EditorSnapshot _createSnapshot() {
    return EditorSnapshot(
      images: List<File>.from(images),
      durations: List<double>.from(durations),
      textClips: _textClips.map((e) => e.copy()).toList(),
      audioClip: _audioClip?.copy(),
      selectedIndex: selectedIndex,
      currentPlayTime: _currentPlayTime,
    );
  }



  void _saveDiscreteUndoState() {
    _undoStack.add(_createSnapshot());
    _redoStack.clear();
  }



  void _restoreSnapshot(EditorSnapshot snapshot) {
    setState(() {
      images = List<File>.from(snapshot.images);
      durations = List<double>.from(snapshot.durations);
      _textClips = snapshot.textClips.map((e) => e.copy()).toList();
      _audioClip = snapshot.audioClip?.copy();
      selectedIndex = snapshot.selectedIndex;
      _currentPlayTime = snapshot.currentPlayTime;
    });
  }
  void _undo() {
    if (_undoStack.isEmpty) return;

    _stopPreview();


    _redoStack.add(
      EditorSnapshot(
        images: List<File>.from(images),
        durations: List<double>.from(durations),
        textClips: _textClips.map((e) => e.copy()).toList(),
        audioClip: _audioClip?.copy(),
        selectedIndex: selectedIndex,
        currentPlayTime: _currentPlayTime,
      ),
    );

    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);
  }



  void _redo() {
    if (_redoStack.isEmpty) return;
    _stopPreview();

    _undoStack.add(
      EditorSnapshot(
        images: List<File>.from(images),
        durations: List<double>.from(durations),
        textClips: _textClips.map((e) => e.copy()).toList(),
        audioClip: _audioClip?.copy(),
        selectedIndex: selectedIndex,
        currentPlayTime: _currentPlayTime,
      ),
    );

    final snapshot = _redoStack.removeLast();
    _restoreSnapshot(snapshot);
  }


  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _zoomAnimation = Tween(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.value = 1.0;
  }

  Future<void> _initMediaStore() async {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "ReelSpark";
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _playbackTicker?.cancel();
    _animationController.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
    textController.dispose();
    super.dispose();
  }

  // ============================================================================
  // PREVIEW & PLAYBACK LOGIC
  // ============================================================================





  void _startAutoPreview() async {
    _playbackTicker?.cancel();

    setState(() => isPlaying = true);

    final videoDuration = _calculateVideoDuration();

    if (_currentPlayTime >= videoDuration - 0.02) {
      _currentPreviewIndex = images.length - 1;
      _stopPreview();
    }

    if (_audioClip != null && _isAudioReady) {
      final seekPosition = _audioClip!.getAudioSeekPosition(_currentPlayTime);
      if (seekPosition != null) {
        await audioPlayer.seek(seekPosition);
        await audioPlayer.resume();
      }
    }

    int frameCount = 0;

    _playbackTicker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        _currentPlayTime += 0.016;

        _checkAudioPlaybackBounds();
        _syncTimelineWithPlayback();
        _updatePreviewIndexFromTime();

        frameCount++;
        if (frameCount >= 4) {
          frameCount = 0;
          if (mounted) {
            setState(() {});
          }
        }

        if (_currentPlayTime >= _calculateTotalDuration() - 0.02) {
          _currentPreviewIndex = images.length - 1;
          _stopPreview();
        }
      },
    );
  }

  void _checkAudioPlaybackBounds() {
    if (_audioClip == null || !_isAudioReady) return;
    final videoDuration = _calculateVideoDuration();

    if (_currentPlayTime >= _audioClip!.trimEnd ||
        _currentPlayTime >= videoDuration) {
      audioPlayer.pause();
    }else if (_currentPlayTime >= _audioClip!.startTime &&
        _currentPlayTime < _audioClip!.endTime &&
        isPlaying) {
      if (audioPlayer.state == PlayerState.paused) {
        final seekPos = _audioClip!.getAudioSeekPosition(_currentPlayTime);
        if (seekPos != null) {
          audioPlayer.seek(seekPos);
          audioPlayer.resume();
        }
      }
    }
  }

  void _stopPreview() async {
    _playbackTicker?.cancel();

    if (_audioClip != null && _isAudioReady) {
      await audioPlayer.pause();
    }

    final controller = TimelineContainer.scrollController;
    if (controller.hasClients) {
      final currentOffset = _calculateTimelineOffsetForTime(_currentPlayTime);

      controller.animateTo(
        currentOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    setState(() => isPlaying = false);
  }

  void _updatePreviewIndexFromTime() {
    double t = 0;

    for (int i = 0; i < durations.length; i++) {
      t += durations[i];
      if (_currentPlayTime < t) {
        if (_currentPreviewIndex != i) {
          setState(() => _currentPreviewIndex = i);
          _animationController.reset();
          _animationController.forward();
        }
        break;
      }
    }
  }

  void _syncTimelineWithPlayback() {
    if (isScrubbing || !mounted) return;
    final controller = TimelineContainer.scrollController;
    if (!controller.hasClients) return;

    const pixelsPerSecond = 60.0;

    final maxOffset = controller.position.maxScrollExtent;
    final targetOffset = (_currentPlayTime * pixelsPerSecond).clamp(0.0, maxOffset);

    _isProgrammaticScroll = true;
    controller.jumpTo(targetOffset);
    _isProgrammaticScroll = false;
  }

  void _onTimelineManualScroll(double timePosition) {
    if (_isProgrammaticScroll || isPlaying) return;

    _currentPlayTime = timePosition.clamp(0.0, _calculateTotalDuration());

    if (_audioClip != null && _isAudioReady) {
      final seekPosition = _audioClip!.getAudioSeekPosition(_currentPlayTime);
      if (seekPosition != null) {
        audioPlayer.seek(seekPosition);
      }
    }

    double t = 0;
    for (int i = 0; i < durations.length; i++) {
      t += durations[i];
      if (_currentPlayTime < t) {
        if (_currentPreviewIndex != i) {
          _currentPreviewIndex = i;
          _animationController.reset();
          _animationController.forward();
        }
        break;
      }
    }

    setState(() {});
  }

  void _togglePlayPause() {
    if (isPlaying) {
      _stopPreview();
    } else {
      _startAutoPreview();
    }
  }

  // ============================================================================
  // IMAGE PICKER LOGIC
  // ============================================================================

  Future<File?> _pickImageFromGallery() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else {
        status = await Permission.photos.request();
      }

      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Storage permission is required to select images'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return null;
      }

      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error picking image: $e')),
        );
      }
      return null;
    }
  }

  // ============================================================================
  // MUSIC LOGIC
  // ============================================================================

  Future<void> pickMusic() async {
    _saveDiscreteUndoState();
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null) return;

      final path = result.files.single.path!;
      final fileName = result.files.single.name;

      _isAudioReady = false;

      await audioPlayer.stop();
      await audioPlayer.setSource(DeviceFileSource(path));

      final duration = await audioPlayer.getDuration();
      final videoDuration = _calculateVideoDuration();




      if (duration != null && mounted) {
        final originalDuration = duration.inMilliseconds / 1000.0;

        final effectiveEnd =
        originalDuration > videoDuration
            ? videoDuration
            : originalDuration;


        setState(() {
          _audioClip = AudioClip(
            path: path,
            fileName: fileName,
            originalDuration: originalDuration,
            startTime: 0.0,
            trimStart: 0.0,
            trimEnd: effectiveEnd, // ✅ LIMITED TO VIDEO
          );
          _isAudioReady = true;
        });

        final seekPosition = Duration(milliseconds: (_currentPlayTime * 1000).toInt());
        await audioPlayer.seek(seekPosition);

        if (isPlaying) {
          await audioPlayer.resume();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🎵 Music added: $fileName')),
          );
        }
      } else {
        throw Exception('Could not get audio duration');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error loading music: $e')),
        );
      }
    }
  }

  void _onAudioClipChanged(AudioClip updatedClip) {
    setState(() {
      _audioClip = updatedClip;
    });

    if (isPlaying && _isAudioReady) {
      final seekPos = updatedClip.getAudioSeekPosition(_currentPlayTime);
      if (seekPos != null) {
        audioPlayer.seek(seekPos);
      }
    }
  }

  // ============================================================================
  // EXPORT LOGIC
  // ============================================================================

  Future<void> exportVideo() async {
    if (isExporting) return;
    setState(() => isExporting = true);

    try {
      final outputPath = await VideoService.exportFinalVideo(
        images: images,
        durations: durations,
        musicPath: _audioClip?.path,
      );

      await MediaStore().saveFile(
        tempFilePath: outputPath,
        dirType: DirType.video,
        dirName: DirName.movies,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Video saved to gallery")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Export failed: $e")),
        );
      }
    } finally {
      setState(() => isExporting = false);
    }
  }


  // ============================================================================
  // TOOL HANDLERS
  // ============================================================================

  void _onAudioTap() {
    setState(() {
      _activeTool = EditorTool.audio;
      _showTextInput = false;
      _showEffectsPanel = false;
    });
    pickMusic();
  }

  void _onTextTap() {
    _saveDiscreteUndoState();
    final start = _currentPlayTime;
    final end = (start + 2.0).clamp(start, _calculateTotalDuration());

    final clip = TextClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'New Text',
      startTime: start,
      endTime: end,
      position: const Offset(80, 120),
      fontSize: 36,
      rotation: 0,
      color: Colors.white,
      fontFamily: 'Poppins',
      opacity: 1.0,
    );

    setState(() {
      _textClips.add(clip);
      _selectedTextClip = clip;
      _activeTool = EditorTool.text;
      _showTextInput = true;
    });

  }

  void _onEffectsTap() {
    final start = _currentPlayTime;
    final end = (start + 2.0).clamp(start, _calculateTotalDuration());

    final clip = EffectClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EffectType.lightLeak,
      startTime: start,
      endTime: end,
    );

    setState(() {
      _effectClips.add(clip);
      _selectedEffectClip = clip;
    });
  }



  void _selectTextClip(TextClip clip) {
    setState(() {
      _selectedTextClip = clip;
      textController.text = clip.text;
      _activeTool = EditorTool.text;
      _showTextInput = true;
    });
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Detect keyboard height
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0.0;

    // Animation durations tuned to be snappy and smooth (CapCut-like)
    const aniDur = Duration(milliseconds: 180);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // We manage insets manually to avoid automatic resizes/flicker
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Main column content
            Column(
              children: [
                // TOP BAR
                EditorTopBar(
                  onBack: () => Navigator.of(context).pop(),
                  onExport: exportVideo,
                  isExporting: isExporting,
                  resolution: 'AI Ultra HD',
                ),

                // PREVIEW AREA
                // We scale the preview down slightly when the keyboard is visible
                // so the preview stays visible while the keyboard opens.
                Expanded(
                  child: AnimatedContainer(
                    duration: aniDur,
                    curve: Curves.easeInOut,
                    // Add a small bottom padding when keyboard is visible so
                    // the preview doesn't get obscured by a docked panel.
                    padding: EdgeInsets.only(bottom: isKeyboardVisible ? 8.0 : 0.0),
                    child: AnimatedScale(
                      scale: isKeyboardVisible ? 0.92 : 1.0,
                      duration: aniDur,
                      curve: Curves.easeInOut,
                      child: PreviewArea(
                        images: images,
                        currentPreviewIndex: _currentPreviewIndex,
                        currentPlayTime: _currentPlayTime,

                        // ✅ NEW: CapCut-style transitions
                        transitions: transitions,
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                        zoomAnimation: _zoomAnimation,
                        effectClips: _effectClips,

                        // Text layer
                        textClips: _textClips,
                        selectedTextClip: _selectedTextClip,

                        onTapOutside: () => setState(() => _selectedTextClip = null),

                        onTextClipSelect: _selectTextClip,

                        onTextPositionChanged: (clip, newPosition) {
                          setState(() => clip.position = newPosition);
                        },

                        onTextFontSizeChanged: (clip, newSize) {
                          setState(() => clip.fontSize = newSize);
                        },

                        onTextRotationChanged: (clip, newRotation) {
                          setState(() => clip.rotation = newRotation);
                        },

                        onTextClipRemove: (clip) {
                          setState(() {
                            _textClips.remove(clip);
                            _selectedTextClip = null;
                          });
                        },

                        onTextClipEdit: (clip) {
                          setState(() {
                            _activeTool = EditorTool.text;
                            _showTextInput = true;
                            _selectedTextClip = clip;
                          });
                        },
                      ),

                    ),
                  ),
                ),

                // TIMELINE CONTROLS
                _buildTimelineControls(),

                // TIMELINE SECTION
                // Add AnimatedPadding so the timeline moves above the keyboard smoothly
                AnimatedPadding(
                  duration: aniDur,
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  curve: Curves.easeInOut,
                  child: _buildTimelineSection(),
                ),

                // NOTE: Panels are now overlaid via Stack (below). We don't
                // render them here to avoid layout jumps when the keyboard opens.
              ],
            ),

            // Overlaid panels: Text input panel and Effects panel
            // They are docked above the keyboard using AnimatedPositioned
            // This keeps the timeline and preview visible and prevents overlap
            if (_showTextInput)
              AnimatedPositioned(
                duration: aniDur,
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                // Position directly above keyboard (or at bottom when closed)
                bottom: keyboardHeight,
                child: Material(
                  color: Colors.transparent,
                  child: TextPanel(
                    textController: textController,
                    selectedTextClip: _selectedTextClip,
                    onTextChanged: (value) {
                      if (_selectedTextClip == null) return;
                      setState(() {
                        _selectedTextClip!.text = value;
                      });
                    },
                    onColorChanged: (color) {
                      if (_selectedTextClip == null) return;
                      setState(() {
                        _selectedTextClip!.color = color;
                      });
                    },
                    onOpacityChanged: (opacity) {
                      if (_selectedTextClip == null) return;
                      setState(() {
                        _selectedTextClip!.opacity = opacity;
                      });
                    },
                    onFontFamilyChanged: (font) {
                      if (_selectedTextClip == null) return;
                      setState(() {
                        _selectedTextClip!.fontFamily = font;
                      });
                    },
                    onDone: () => setState(() => _showTextInput = false),
                  ),
                ),
              ),

            if (_showEffectsPanel)
              AnimatedPositioned(
                duration: aniDur,
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: EffectsPanel(
                  transitionType: transitionType,
                  onTransitionChanged: (type) {
                    setState(() => transitionType = type);
                  },
                  onClose: () => setState(() => _showEffectsPanel = false),
                ),
              ),
          ],
        ),
      ),

      // BOTTOM BAR
      // Hide bottom toolbar while keyboard is visible to avoid overlap
      bottomNavigationBar: isKeyboardVisible
          ? const SizedBox.shrink()
          : EditorBottomBar(
              activeTool: _activeTool,
              onAudio: _onAudioTap,
              onText: _onTextTap,
              onEffects: _onEffectsTap,
            ),
    );
  }

  // ============================================================================
  // UI COMPONENTS
  // ============================================================================
  Widget _buildTimelineControls() {
    final currentTime = _calculateCurrentTime();
    final totalTime = _calculateTotalTime();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // LEFT: time (single source)
          SizedBox(
            width: 110,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                '$currentTime / $totalTime',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),

          // CENTER: play / pause (true center)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // RIGHT: undo / redo / delete ONLY
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _smallIconButton(
                  icon: Icons.undo,
                  onTap: _undoStack.isNotEmpty ? _undo : () {},
                ),

                const SizedBox(width: 6),

                _smallIconButton(
                  icon: Icons.redo,
                  onTap: _redoStack.isNotEmpty ? _redo : () {},
                ),

                const SizedBox(width: 6),

                _smallIconButton(
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                  onTap: _deleteSelectedItem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small icon button with disabled state handling.

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color color = Colors.white54,
  }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }



  void _deleteSelectedItem() {
    _saveDiscreteUndoState();
    // 1️⃣ Delete selected text
    if (_selectedTextClip != null) {
      setState(() {
        _textClips.remove(_selectedTextClip);
        _selectedTextClip = null;
        _showTextInput = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Text deleted')),
      );
      return;
    }

    // 2️⃣ Delete audio
    if (_audioClip != null) {
      audioPlayer.stop();

      setState(() {
        _audioClip = null;
        _isAudioReady = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Music removed')),
      );
      return;
    }

    // 3️⃣ Delete selected image (clip)
    if (images.length > 1) {
      setState(() {
        images.removeAt(selectedIndex);
        durations.removeAt(selectedIndex);

        selectedIndex =
            selectedIndex.clamp(0, images.length - 1);
        _currentPreviewIndex = selectedIndex;
        _currentPlayTime =
            _calculateStartTimeForIndex(selectedIndex);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Image deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ At least one image is required')),
      );
    }
  }


  String _calculateCurrentTime() {
    final time = _currentPlayTime;
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _calculateTotalTime() {
    final total = _calculateTotalDuration();
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildTimelineSection() {
    final hasMusic = _audioClip != null;
    final hasTextClips = _textClips.isNotEmpty;
    final baseHeight = 140.0;
    final textTrackSpace = hasTextClips ? 44.0 : 0.0;
    final audioTrackSpace = hasMusic ? 56.0 : 0.0;

    return Container(
      height: baseHeight + textTrackSpace + audioTrackSpace,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: Stack(
        children: [
          Positioned.fill(
             child: TimelineContainer(
               // ===================== CORE DATA =====================
               images: images,
               durations: durations,
               transitions: transitions,
               selectedIndex: selectedIndex,
               isPlaying: isPlaying,

              // ===================== EFFECTS (NEW) =====================
              effectClips: _effectClips,
              onEffectSelect: (clip) {
                setState(() {
                  _selectedEffectClip = clip;
                  _currentPlayTime = clip.startTime;
                });
              },
              onEffectMove: (clip, newStart, newEnd) {
                setState(() {
                  clip.startTime = newStart;
                  clip.endTime = newEnd;
                  _currentPlayTime = newStart;
                });
              },

               // ===================== TRANSITION HANDLER =====================
               onAddTransition: (index) {
                 _openTransitionPicker(index); // ✅ opens bottom sheet
               },

              // ===================== AUDIO =====================
              audioClip: _audioClip,
              onAudioClipChanged: _onAudioClipChanged,

              // ===================== TEXT =====================
              textClips: _textClips,
              selectedTextClip: _selectedTextClip,
              onTextClipSelect: (clip) {
                setState(() {
                  _selectedTextClip = clip;
                  _currentPlayTime = clip.startTime;
                  _activeTool = EditorTool.text;
                  _showTextInput = true;
                  textController.text = clip.text;
                });
              },
              onTextClipTrim: (clip, newStart, newEnd) {
                setState(() {
                  clip.startTime = newStart;
                  clip.endTime = newEnd;
                });
              },
              onTextClipMove: (clip, newStart, newEnd) {
                setState(() {
                  clip.startTime = newStart;
                  clip.endTime = newEnd;
                  _currentPlayTime = newStart;
                });
              },

              // ===================== CLIP SELECTION =====================
              onSelect: (i) {
                setState(() {
                  selectedIndex = i;
                  _currentPreviewIndex = i;
                  _currentPlayTime = _calculateStartTimeForIndex(i);
                });

                if (_audioClip != null && _isAudioReady) {
                  final seekPosition =
                  _audioClip!.getAudioSeekPosition(_currentPlayTime);
                  if (seekPosition != null) {
                    audioPlayer.seek(seekPosition);
                  }
                }
              },

              // ===================== REORDER (FIXED FOR TRANSITIONS) =====================
              onReorder: (imgs, durs) {
                setState(() {
                  images = imgs;
                  durations = durs;

                  // ✅ keep transitions aligned
                  transitions = List.generate(images.length - 1, (i) {
                    return i < transitions.length ? transitions[i] : null;
                  });
                });
              },

              // ===================== DURATION =====================
              onDurationDragStart: _onDurationDragStart,
              onDurationDragEnd: _onDurationDragEnd,
              onDurationChange: (d) {
                setState(() {
                  durations[selectedIndex] = d;

                  if (_audioClip != null) {
                    final videoDuration = _calculateVideoDuration();
                    if (_audioClip!.trimEnd > videoDuration) {
                      _audioClip = _audioClip!.copyWith(
                        trimEnd: videoDuration,
                      );
                    }
                  }
                });
              },

              // ===================== TIMELINE SCROLL =====================
              onTimelineScroll: _onTimelineManualScroll,
            ),

          ),

          // Add Image Button
          Positioned(
            right: 12,
            top: 42,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  _saveDiscreteUndoState();
                  await Future.delayed(const Duration(milliseconds: 120));

                  final File? image = await _pickImageFromGallery();
                  if (image == null) return;
                  setState(() {
                    images.add(image);
                    durations.add(2.0);
                    selectedIndex = images.length - 1;
                    _currentPreviewIndex = selectedIndex;
                  });

                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white54),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _openTransitionPicker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return TransitionPicker(
          onSelect: (transition) {
            setState(() {
              transitions[index] = transition;
            });
          },
        );
      },
    );
  }

  void _onReorderWithTransitions(List<File> imgs, List<double> durs) {
    setState(() {
      images = imgs;
      durations = durs;
      transitions = List.generate(images.length - 1, (i) {
        return i < transitions.length ? transitions[i] : null;
      });
    });
  }


  Widget _buildTextPanel() {
    return TextPanel(
      textController: textController,
      selectedTextClip: _selectedTextClip,
      onTextChanged: (value) {
        if (_selectedTextClip == null) return;
        setState(() {
          _selectedTextClip!.text = value;
        });
      },
      onColorChanged: (color) {
        if (_selectedTextClip == null) return;
        setState(() {
          _selectedTextClip!.color = color;
        });
      },
      onOpacityChanged: (opacity) {
        if (_selectedTextClip == null) return;
        setState(() {
          _selectedTextClip!.opacity = opacity;
        });
      },
      onFontFamilyChanged: (font) {
        if (_selectedTextClip == null) return;
        setState(() {
          _selectedTextClip!.fontFamily = font;
        });
      },
      onDone: () => setState(() => _showTextInput = false),
    );
  }

  Widget _buildEffectsPanel() {
    return EffectsPanel(
      transitionType: transitionType,
      onTransitionChanged: (type) {
        setState(() => transitionType = type);
      },
      onClose: () => setState(() => _showEffectsPanel = false),
    );
  }
}



class EditorSnapshot {
  final List<File> images;
  final List<double> durations;
  final List<TextClip> textClips;
  final AudioClip? audioClip;
  final int selectedIndex;
  final double currentPlayTime;

  EditorSnapshot({
    required this.images,
    required this.durations,
    required this.textClips,
    required this.audioClip,
    required this.selectedIndex,
    required this.currentPlayTime,
  });
}
