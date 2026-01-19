import '../services/template_render_service.dart';
import '../templates.dart';

/// Full render/export screen.
///
/// Responsibilities:
/// - Kicks off [TemplateRenderService.renderExport] after first frame.
/// - Shows a progress indicator based on FFmpeg statistics.
/// - On success: navigates to [TemplateExportScreen] (replace this screen).
/// - On failure: shows a readable error + allows going back.
class TemplateRenderingScreen extends StatefulWidget {
  final VideoTemplate template;
  final List<File> images;

  /// Optional replacement music chosen by the user.
  /// Can be an asset path or a device file path.
  final String? musicOverride;

  const TemplateRenderingScreen({
    super.key,
    required this.template,
    required this.images,
    this.musicOverride,
  });

  @override
  State<TemplateRenderingScreen> createState() => _TemplateRenderingScreenState();
}

class _TemplateRenderingScreenState extends State<TemplateRenderingScreen> {
  Object? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Wait until after build so context/navigation is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      final path = await TemplateRenderService.renderExport(
        context: context,
        images: widget.images,
        template: widget.template,
        musicOverride: widget.musicOverride,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
          });
        },
      );

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateExportScreen(videoPath: path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Generating video',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        // If we have an error, allow user to go back.
        automaticallyImplyLeading: _error != null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Center(
                    child: _error == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Rendering… $percent%',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: _progress > 0
                                          ? _progress.clamp(0.0, 1.0)
                                          : null,
                                      color: const Color(0xFF16A34A),
                                      backgroundColor: Colors.black12,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Generating HD video with music. This can take a little time.',
                                  textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 52),
                              const SizedBox(height: 12),
                              const Text(
                                'Render failed',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
