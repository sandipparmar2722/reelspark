import 'package:reelspark/ui/editor/editor.dart';

/// Audio panel widget (placeholder for future features)
///
/// Contains:
/// - Music file info
/// - Volume control
/// - Trim controls
class AudioPanel extends StatelessWidget {
  /// Audio file name
  final String? fileName;

  /// Audio duration in seconds
  final double? duration;

  /// Current volume (0.0 to 1.0)
  final double volume;

  /// Callback when volume changes
  final Function(double)? onVolumeChanged;

  /// Callback when pick music is tapped
  final VoidCallback? onPickMusic;

  /// Callback when remove music is tapped
  final VoidCallback? onRemoveMusic;

  /// Callback when panel is closed
  final VoidCallback? onClose;

  const AudioPanel({
    super.key,
    this.fileName,
    this.duration,
    this.volume = 1.0,
    this.onVolumeChanged,
    this.onPickMusic,
    this.onRemoveMusic,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Content
          if (fileName == null) ...[
            // No audio - show pick button
            GestureDetector(
              onTap: onPickMusic,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Add Music',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Has audio - show info and controls
            Row(
              children: [
                const Icon(Icons.music_note, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (duration != null)
                        Text(
                          '${duration!.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemoveMusic,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Volume control
            Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.green,
                      thumbColor: Colors.green,
                    ),
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: onVolumeChanged,
                    ),
                  ),
                ),
                Text(
                  '${(volume * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

