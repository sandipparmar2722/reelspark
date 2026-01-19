
import '../templates.dart';

class TemplateDetailScreen extends StatefulWidget {
  final VideoTemplate template;

  const TemplateDetailScreen({super.key, required this.template});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  late final PageController _pageController;
  List<VideoTemplate> _templates = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await const TemplateRepository().loadTemplates();
    final initialIndex = templates.indexWhere((t) => t.id == widget.template.id);

    setState(() {
      _templates = templates;
      _currentIndex = initialIndex >= 0 ? initialIndex : 0;
      _pageController = PageController(initialPage: _currentIndex);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for Reels-style scrolling
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _templates.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _TemplateReelItem(
                template: _templates[index],
                isActive: index == _currentIndex,
              );
            },
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Scroll indicator at bottom
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateReelItem extends StatefulWidget {
  final VideoTemplate template;
  final bool isActive;

  const _TemplateReelItem({
    required this.template,
    required this.isActive,
  });

  @override
  State<_TemplateReelItem> createState() => _TemplateReelItemState();
}

class _TemplateReelItemState extends State<_TemplateReelItem> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isLiked = false;
  bool _isInitialized = false;
  bool _isVideoReady = false;
  bool _shouldPlayWhenReady = false;

  @override
  void initState() {
    super.initState();
    _shouldPlayWhenReady = widget.isActive;
    _initAudio();
    _initVideo();

  }

  @override
  void didUpdateWidget(covariant _TemplateReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _shouldPlayWhenReady = true;
      _playMedia();
    } else if (!widget.isActive && oldWidget.isActive) {
      _shouldPlayWhenReady = false;
      _stopMedia();
    }
  }

  void _playMedia() {
    if (_isVideoReady) {
      _videoController?.seekTo(Duration.zero);
      _videoController?.play();
    }
    _playAudio();
  }

  Future<void> _playAudio() async {
    if (_audioPlayer == null) return;

    try {
      // Stop any current playback
      await _audioPlayer!.stop();
      // Reload the asset to ensure fresh playback
      await _audioPlayer!.setAsset(widget.template.music);
      if (mounted && _shouldPlayWhenReady) {
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _stopMedia() {
    _videoController?.pause();
    _audioPlayer?.stop();
  }


  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.template.previewVideo);
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // Mute video since we have separate audio
      if (!mounted) return;

      _isVideoReady = true;
      if (_shouldPlayWhenReady) {
        await controller.play();
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  Future<void> _initAudio() async {
    final audioPlayer = AudioPlayer();
    _audioPlayer = audioPlayer;

    try {
      await audioPlayer.setAsset(widget.template.music);
      await audioPlayer.setLoopMode(LoopMode.one);
      if (!mounted) return;

      if (_shouldPlayWhenReady) {
        await audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _shouldPlayWhenReady = widget.isActive;
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
  }

  void _shareTemplate() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this amazing template: ${widget.template.title}',
        subject: 'ReelSpark Template',
      ),
    );
  }

  String _getMusicName() {
    final music = widget.template.music;
    // Extract file name from path
    final fileName = music.split('/').last.split('.').first;
    // Make it more readable
    return fileName.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player - Full screen
          if (_isInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                // Like button
                _ActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  iconColor: _isLiked ? Colors.red : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),

                // Share button
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _shareTemplate,
                ),
                const SizedBox(height: 20),

                // Download button with badge
                _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  showBadge: true,
                  badgeCount: widget.template.resolvedSlots,
                  onTap: () {
                    // Stop media before navigating
                    _stopMedia();
                    // Navigate to editor for download
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TemplateEditorScreen(template: widget.template),
                      ),
                    ).then((_) {
                      // Resume media when returning
                      if (widget.isActive && mounted) {
                        _playMedia();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Similar button
                _ActionButton(
                  icon: Icons.video_library_rounded,
                  label: 'Similar',
                  onTap: () {
                    // Show similar templates (same category)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Browse more ${widget.template.category} templates'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom info section
          Positioned(
            left: 16,
            right: 90,
            bottom: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template title
                Text(
                  widget.template.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Image count row
                Row(
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '0 ~ ${widget.template.resolvedSlots}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Music row
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getMusicName(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Make Video Button - Gradient style
          Positioned(
            left: 16,
            right: 16,
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            child: GestureDetector(
              onTap: () {
                // Stop media before navigating
                _stopMedia();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplateEditorScreen(template: widget.template),
                  ),
                ).then((_) {
                  // Resume media when returning
                  if (widget.isActive && mounted) {
                    _playMedia();
                  }
                });
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFA726), // Orange
                      Color(0xFFE040FB), // Purple/Magenta
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE040FB).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Make video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
