import '../templates.dart';

class TemplateEditorScreen extends StatefulWidget {
  final VideoTemplate template;

  const TemplateEditorScreen({super.key, required this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  late final List<File?> _slots;
  final ScrollController _slotsController = ScrollController();
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    _slots = List<File?>.filled(widget.template.resolvedSlots, null, growable: false);
  }

  @override
  void dispose() {
    _slotsController.dispose();
    super.dispose();
  }

  bool get _canRender => _slots.every((e) => e != null) && !_rendering;

  Future<void> _pickMultipleFromGallery({int startIndex = 0}) async {
    final remaining = _slots.length - startIndex;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      var i = startIndex;
      for (final x in picked) {
        if (i >= _slots.length) break;
        _slots[i] = File(x.path);
        i++;
      }
    });

    // Scroll to the next empty slot if any.
    final nextIndex = _slots.indexWhere((f) => f == null);
    if (!mounted || nextIndex == -1) return;

    await _slotsController.animateTo(
      (nextIndex * (110 + 12)).toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickForSlot(int index) async {
    // Prefer multi-select when user taps an empty slot.
    // If they select multiple, we fill from this slot forward.
    if (_slots[index] == null) {
      await _pickMultipleFromGallery(startIndex: index);
      return;
    }

    // If slot already has an image, allow replacing single image.
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _slots[index] = File(x.path);
    });

    // Auto-scroll to the next empty slot to make adding multiple images obvious.
    final nextIndex = _slots.indexWhere((f) => f == null);
    if (!mounted || nextIndex == -1) return;

    await _slotsController.animateTo(
      (nextIndex * (110 + 12)).toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to slot ${index + 1}. Tap slot ${nextIndex + 1} to add next image.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeSlot(int index) {
    setState(() {
      _slots[index] = null;
    });
  }

  Future<void> _render() async {
    if (!_canRender) return;

    setState(() => _rendering = true);
    try {
      final images = _slots.whereType<File>().toList(growable: false);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateRenderingScreen(
            template: widget.template,
            images: images,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  Future<void> _openPreview() async {
    if (!_canRender) return;
    final images = _slots.whereType<File>().toList(growable: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateLivePreviewScreen(
          template: widget.template,
          images: images,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled = _slots.whereType<File>().length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Select photos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Pick multiple',
            onPressed: _rendering ? null : () => _pickMultipleFromGallery(startIndex: 0),
            icon: const Icon(Icons.photo_library_outlined, color: Colors.black87),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add your photos',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$filled/${_slots.length}',
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 140,
            child: ListView.separated(
              controller: _slotsController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final img = _slots[i];
                return _SlotTile(
                  index: i,
                  image: img,
                  onTap: () => _pickForSlot(i),
                  onRemove: img == null ? null : () => _removeSlot(i),
                );
              },
            ),
          ),

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_creation_outlined, color: Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This will generate a video using your photos and the template music.',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.70)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _canRender ? _openPreview : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0x3316A34A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canRender ? _render : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black12,
                      disabledForegroundColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _rendering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Generate video',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tip: Tap the first empty slot to select multiple photos at once.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final int index;
  final File? image;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SlotTile({
    required this.index,
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 120,
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: image == null ? const Color(0xFFF2F4F7) : Colors.black12,
                  border: Border.all(
                    color: image == null ? Colors.black12 : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: image == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.black54, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Slot ${index + 1}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image(
                        image: ResizeImage(
                          FileImage(image!),
                          width: 360,
                          height: 420,
                        ),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stack) {
                          return const Center(
                            child: Text(
                              'Failed to load',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Overlays for filled slots
            if (image != null)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
