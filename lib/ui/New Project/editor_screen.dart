import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:reelspark/ui/New Project/widget/timeline_widget.dart';
import 'package:reelspark/ui/New Project/widget/editor_bottom_bar.dart';
import 'package:reelspark/ui/New Project/widget/editor_top_bar.dart';
import 'package:reelspark/models/audio_clip.dart';
import '../../services/New Project/video_service.dart';
// ============================================================================
// TRANSITION TYPE ENUM
// ============================================================================
/// Available transition effects between slides.
enum TransitionType { fade, slide, zoom }

// ============================================================================
// EDITOR SCREEN - CAPCUT STYLE
// ============================================================================
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
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // --- Audio Clip (replaces old musicPath/musicFileName/musicDuration) ---
  AudioClip? _audioClip;

  // === SINGLE SOURCE OF TRUTH FOR PLAYBACK ===
  double _currentPlayTime = 0.0; // Current playback position in seconds
  Timer? _playbackTicker;
  bool _isProgrammaticScroll = false; // Flag to prevent feedback loop
  bool _isAudioReady = false; // Flag to track if audio is loaded

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
  Offset textPosition = const Offset(80, 120);
  double fontSize = 36;
  Color textColor = Colors.white;

  // --- Music ---
  final AudioPlayer audioPlayer = AudioPlayer();

  // --- UI State ---
  EditorTool? _activeTool;
  bool _showTextInput = false;
  bool _showEffectsPanel = false;





  double _calculateStartTimeForIndex(int index) {
    double time = 0;
    for (int i = 0; i < index; i++) {
      time += durations[i];
    }
    return time;
  }

  double _calculateTotalDuration() {
    return durations.fold(0.0, (sum, d) => sum + d);
  }


  double _calculateTimelineOffsetForTime(double time) {
    const pixelsPerSecond = 60.0;

    final controller = TimelineWidget.scrollController;
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

    _initMediaStore();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPreview());
  }

  /// Initialize animation controller and all transition animations.
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
    audioPlayer.stop(); // Stop audio when screen closes
    audioPlayer.dispose();
    textController.dispose();
    super.dispose();
  }



  // ============================================================================
  // PREVIEW & PLAYBACK LOGIC (CAPCUT-STYLE)
  // ============================================================================

  /// Starts smooth playback with timeline scrolling synchronized to playhead
  void _startAutoPreview() async {
    _playbackTicker?.cancel();

    setState(() => isPlaying = true);

    // If starting fresh from beginning or after reaching end, reset to start
    if (_currentPlayTime >= _calculateTotalDuration() - 0.1) {
      _currentPlayTime = 0.0;
      _currentPreviewIndex = 0;
    }

    // 🎵 SEEK AUDIO TO CURRENT POSITION (using trim offsets)
    if (_audioClip != null && _isAudioReady) {
      final seekPosition = _audioClip!.getAudioSeekPosition(_currentPlayTime);
      if (seekPosition != null) {
        await audioPlayer.seek(seekPosition);
        await audioPlayer.resume();
      }
    }

    int frameCount = 0;

    _playbackTicker = Timer.periodic(
      const Duration(milliseconds: 16), // 60 FPS
          (_) {
        // ⏱ UPDATE PLAY TIME
        _currentPlayTime += 0.016;

        // 🎵 CHECK IF AUDIO SHOULD STOP (reached trim end)
        _checkAudioPlaybackBounds();

        // 🎞 TIMELINE + PREVIEW SYNC
        _syncTimelineWithPlayback();
        _updatePreviewIndexFromTime();

        // 🔄 REDUCE REBUILDS
        frameCount++;
        if (frameCount >= 4) {
          frameCount = 0;
          if (mounted) {
            setState(() {});
          }
        }

        // ⛔ END PLAYBACK
        if (_currentPlayTime >= _calculateTotalDuration() - 0.02) {
          _currentPreviewIndex = images.length - 1;
          _stopPreview();
        }
      },
    );
  }

  /// Check if audio should stop playing based on trim bounds
  void _checkAudioPlaybackBounds() {
    if (_audioClip == null || !_isAudioReady) return;

    // Stop audio if we've gone past the audio clip's end time
    if (_currentPlayTime >= _audioClip!.endTime) {
      audioPlayer.pause();
    }
    // Start audio if we've entered the audio clip's range
    else if (_currentPlayTime >= _audioClip!.startTime &&
             _currentPlayTime < _audioClip!.endTime &&
             isPlaying) {
      // Check if audio is paused and should be playing
      if (audioPlayer.state == PlayerState.paused) {
        final seekPos = _audioClip!.getAudioSeekPosition(_currentPlayTime);
        if (seekPos != null) {
          audioPlayer.seek(seekPos);
          audioPlayer.resume();
        }
      }
    }
  }

  /// Stops playback - pauses audio without resetting position
  void _stopPreview() async {
    _playbackTicker?.cancel();

    // 🎵 PAUSE AUDIO (not stop - to preserve position)
    if (_audioClip != null && _isAudioReady) {
      await audioPlayer.pause();
    }

    final controller = TimelineWidget.scrollController;
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

  /// Updates the preview image index based on current playback time
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


  /// Synchronizes timeline scrolling with playback - CapCut style
  /// Timeline scrolls smoothly while playhead stays fixed in center
  void _syncTimelineWithPlayback() {
    if (isScrubbing || !mounted) return;
    final controller = TimelineWidget.scrollController;
    if (!controller.hasClients) return;

    const pixelsPerSecond = 60.0;

    // ✅ Calculate target offset directly - padding already centers playhead
    final maxOffset = controller.position.maxScrollExtent;
    final targetOffset = (_currentPlayTime * pixelsPerSecond).clamp(0.0, maxOffset);

    // Set flag before jumping to prevent feedback loop
    _isProgrammaticScroll = true;

    // Use jumpTo for smooth, jitter-free scrolling
    controller.jumpTo(targetOffset);

    // Reset flag immediately - the scroll listener will check this flag
    _isProgrammaticScroll = false;
  }

  /// Handles manual timeline scrolling - updates playback position and seeks audio
  void _onTimelineManualScroll(double timePosition) {
    // Ignore if this is a programmatic scroll or if we're actively playing
    if (_isProgrammaticScroll || isPlaying) return;

    // Update playback time to match timeline position
    _currentPlayTime = timePosition.clamp(0.0, _calculateTotalDuration());

    // 🎵 SEEK AUDIO to new position using trim offsets (while paused)
    if (_audioClip != null && _isAudioReady) {
      final seekPosition = _audioClip!.getAudioSeekPosition(_currentPlayTime);
      if (seekPosition != null) {
        audioPlayer.seek(seekPosition);
      }
    }

    // Update preview index based on new time
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

    // Update UI to show current time
    setState(() {});
  }

  /// Toggles between play and pause
  void _togglePlayPause() {
    if (isPlaying) {
      _stopPreview();
    } else {
      _startAutoPreview();
    }
  }

  /// Goes to next clip
  void _goToNext() {
    final nextIndex = (_currentPreviewIndex + 1) % images.length;
    setState(() => _currentPreviewIndex = nextIndex);
    _currentPlayTime = _calculateStartTimeForIndex(nextIndex);
    _animationController.reset();
    _animationController.forward();
  }

  /// Handles transition to a specific index
  void _transitionTo(int index) {
    setState(() => _currentPreviewIndex = index);
    _animationController
      ..reset()
      ..forward();
  }




  // ============================================================================
  // IMAGE PICKER LOGIC
  // ============================================================================


  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> _pickImageFromGallery() async {
    try {
      // Request storage permission
      PermissionStatus status;

      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), request photos permission
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();

          // Fallback to storage permission for older Android versions
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else {
        // For iOS
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

      // Pick image from gallery
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
  // MUSIC LOGIC (with AudioClip model for trim support)
  // ============================================================================

  Future<void> pickMusic() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null) return;

      final path = result.files.single.path!;
      final fileName = result.files.single.name;

      // Reset audio ready flag
      _isAudioReady = false;

      // Stop any existing audio
      await audioPlayer.stop();

      // Set the audio source (preload without playing)
      await audioPlayer.setSource(DeviceFileSource(path));

      // Get duration directly - more reliable than listener
      final duration = await audioPlayer.getDuration();

      if (duration != null && mounted) {
        final originalDuration = duration.inMilliseconds / 1000.0;

        setState(() {
          // Create AudioClip with full duration (user can trim later)
          _audioClip = AudioClip(
            path: path,
            fileName: fileName,
            originalDuration: originalDuration,
            startTime: 0.0,
            trimStart: 0.0,
            trimEnd: originalDuration,
          );
          _isAudioReady = true;
        });

        // Seek to current timeline position
        final seekPosition = Duration(milliseconds: (_currentPlayTime * 1000).toInt());
        await audioPlayer.seek(seekPosition);

        // If currently playing, start audio too
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

  /// Callback when audio clip is trimmed in timeline
  void _onAudioClipChanged(AudioClip updatedClip) {
    setState(() {
      _audioClip = updatedClip;
    });

    // If currently playing, seek audio to correct position
    if (isPlaying && _isAudioReady) {
      final seekPos = updatedClip.getAudioSeekPosition(_currentPlayTime);
      if (seekPos != null) {
        audioPlayer.seek(seekPos);
      }
    }
  }


  // ============================================================================
  // EXPORT LOGIC (UNCHANGED)
  // ============================================================================

  Future<void> exportVideo() async {
    if (isExporting) return;
    setState(() => isExporting = true);

    try {
      final size = MediaQuery.of(context).size;
      final scaledTextPosition = Offset(
        (textPosition.dx / size.width) * 720,
        (textPosition.dy / size.height) * 1280,
      );

      final outputPath = await VideoService.exportFinalVideo(
        images: images,
        durations: durations,
        text: textController.text,
        textPosition: scaledTextPosition,
        textSize: fontSize,
        textColor: textColor,
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
  // TRANSITION BUILDER (UNCHANGED)
  // ============================================================================

  Widget _buildTransition(Widget child) {
    switch (transitionType) {
      case TransitionType.slide:
        return SlideTransition(position: _slideAnimation, child: child);
      case TransitionType.zoom:
        return ScaleTransition(scale: _zoomAnimation, child: child);
      case TransitionType.fade:
        return FadeTransition(opacity: _fadeAnimation, child: child);
    }
  }

  // ============================================================================
  // TOOL HANDLERS
  // ============================================================================

  /// Handle Audio tool tap - opens file picker.
  void _onAudioTap() {
    setState(() {
      _activeTool = EditorTool.audio;
      _showTextInput = false;
      _showEffectsPanel = false;
    });
    pickMusic();
  }

  /// Handle Text tool tap - shows text input panel.
  void _onTextTap() {
    setState(() {
      _activeTool = EditorTool.text;
      _showTextInput = !_showTextInput;
      _showEffectsPanel = false;
    });
  }

  /// Handle Effects tool tap - shows transition picker.
  void _onEffectsTap() {
    setState(() {
      _activeTool = EditorTool.effects;
      _showTextInput = false;
      _showEffectsPanel = !_showEffectsPanel;
    });
  }


  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Dark black like CapCut
      body: Column(
        children: [
          // ============================================
          // TOP BAR: Back, Resolution, Export
          // ============================================
          EditorTopBar(
            onBack: () => Navigator.of(context).pop(),
            onExport: exportVideo,
            isExporting: isExporting,
            resolution: 'AI Ultra HD',
          ),

          // ============================================
          // PREVIEW AREA: 9:16 with rounded corners
          // ============================================
          Expanded(
            child: _buildPreviewArea(),
          ),

          // ============================================
          // TIMELINE CONTROLS: Time display, undo/redo
          // ============================================
          _buildTimelineControls(),

          // ============================================
          // TIMELINE: Horizontal scrollable clips
          // ============================================

          // used for inscre and decrese duration of clips
          _buildTimelineSection(),

          // ============================================
          // EXPANDABLE PANELS: Text Input / Effects
          // ============================================
          if (_showTextInput) _buildTextInputPanel(),
          if (_showEffectsPanel) _buildEffectsPanel(),
        ],
      ),

      // ============================================
      // BOTTOM BAR: Audio, Text, Effects tools
      // ============================================
      bottomNavigationBar: EditorBottomBar(
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

  /// Builds the main preview area with video/image display and play button overlay.
  Widget _buildPreviewArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Image with Transition ---
              _buildTransition(
                Image.file(
                  images[_currentPreviewIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // --- Text Overlay (Draggable) ---
              if (textController.text.isNotEmpty)
                Positioned(
                  left: textPosition.dx,
                  top: textPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() => textPosition += d.delta),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        textController.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  /// Builds the timeline controls row (time display, undo/redo).
  Widget _buildTimelineControls() {
    final currentTime = _calculateCurrentTime();
    final totalTime = _calculateTotalTime();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ===== LEFT + RIGHT CONTROLS =====
          Row(
            children: [
              // --- Current Time ---
              Text(
                '$currentTime / $totalTime',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),

              const Spacer(),

              // --- Undo ---
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.undo, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 16),

              // --- Redo ---
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.redo, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 8),

              // --- Total Duration ---
              Text(
                totalTime,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // ===== CENTER PLAY / PAUSE BUTTON =====
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 30,
              height: 30,
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
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates current playback time string.
  String _calculateCurrentTime() {
    final time = _currentPlayTime;
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Calculates total project duration string.
  String _calculateTotalTime() {
    final total = _calculateTotalDuration();
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total.toInt() % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Builds the CapCut-style timeline section with clip thumbnails.
  ///
  /// Features:
  /// - Horizontal scrolling clips
  /// - Fixed center playhead
  /// - Drag clip edges to resize duration
  /// - Separate audio track below video track with trim handles
  Widget _buildTimelineSection() {
    // Dynamic height: base + audio track if music is present
    final hasMusic = _audioClip != null;
    final baseHeight = 140.0; // Ruler + Video track + padding
    final audioTrackSpace = hasMusic ? 56.0 : 0.0; // Audio track + spacing

    return Container(
      height: baseHeight + audioTrackSpace,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: Stack(
        children: [
          // TIMELINE
          Positioned.fill(
            child: TimelineWidget(
              audioClip: _audioClip,
              onAudioClipChanged: _onAudioClipChanged,
              images: images,
              durations: durations,
              selectedIndex: selectedIndex,
              isPlaying: isPlaying,
              onSelect: (i) {
                setState(() {
                  selectedIndex = i;
                  _currentPreviewIndex = i;
                  _currentPlayTime = _calculateStartTimeForIndex(i);
                });

                // 🎵 SEEK AUDIO to clip start position using trim offsets
                if (_audioClip != null && _isAudioReady) {
                  final seekPosition = _audioClip!.getAudioSeekPosition(_currentPlayTime);
                  if (seekPosition != null) {
                    audioPlayer.seek(seekPosition);
                  }
                }
              },
              onReorder: (imgs, durs) {
                setState(() {
                  images = imgs;
                  durations = durs;
                });
              },
              onDurationChange: (d) {
                setState(() => durations[selectedIndex] = d);
              },
              onTimelineScroll: _onTimelineManualScroll,
              onAddEffect: () {
                setState(() {
                  _activeTool = EditorTool.effects;
                  _showTextInput = false;
                  _showEffectsPanel = true;
                });
              },
            ),
          ),

          // ➕ CAPCUT-STYLE ADD IMAGE OVERLAY BUTTON
          Positioned(
            right: 12,
            top: 42,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  debugPrint("✅ Add image button tapped");

                  await Future.delayed(
                    const Duration(milliseconds: 120),
                  );

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


  /// Builds the text input panel (shown when Text tool is active).
  Widget _buildTextInputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            children: [
              const Text(
                'Add Text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showTextInput = false),
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Text Input Field ---
          TextField(
            controller: textController,
            style: const TextStyle(color: Colors
                .white),
            decoration: InputDecoration(
              hintText: 'Enter your text...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  /// Builds the effects/transitions panel (shown when Effects tool is active).
  Widget _buildEffectsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            children: [
              const Text(
                'Transitions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showEffectsPanel = false),
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Transition Options ---
          Row(
            children: [
              _buildTransitionOption(
                icon: Icons.blur_on,
                label: 'Fade',
                type: TransitionType.fade,
              ),
              const SizedBox(width: 16),
              _buildTransitionOption(
                icon: Icons.swap_horiz,
                label: 'Slide',
                type: TransitionType.slide,
              ),
              const SizedBox(width: 16),
              _buildTransitionOption(
                icon: Icons.zoom_in,
                label: 'Zoom',
                type: TransitionType.zoom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single transition option button.
  Widget _buildTransitionOption({
    required IconData icon,
    required String label,
    required TransitionType type,
  }) {
    final isSelected = transitionType == type;

    return GestureDetector(
      onTap: () => setState(() => transitionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white12 : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white38 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
