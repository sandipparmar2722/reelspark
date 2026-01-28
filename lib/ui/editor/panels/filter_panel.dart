import 'package:reelspark/ui/editor/editor.dart';

/// Filter panel widget (placeholder for future features)
///
/// Contains:
/// - Filter presets
/// - Intensity slider
class FilterPanel extends StatelessWidget {
  /// Current filter name
  final String? currentFilter;

  /// Filter intensity (0.0 to 1.0)
  final double intensity;

  /// Callback when filter changes
  final Function(String?)? onFilterChanged;

  /// Callback when intensity changes
  final Function(double)? onIntensityChanged;

  /// Callback when panel is closed
  final VoidCallback? onClose;

  const FilterPanel({
    super.key,
    this.currentFilter,
    this.intensity = 1.0,
    this.onFilterChanged,
    this.onIntensityChanged,
    this.onClose,
  });

  static const List<Map<String, dynamic>> _filters = [
    {'name': 'None', 'color': Colors.white},
    {'name': 'Warm', 'color': Colors.orange},
    {'name': 'Cool', 'color': Colors.blue},
    {'name': 'Vintage', 'color': Colors.brown},
    {'name': 'B&W', 'color': Colors.grey},
    {'name': 'Vivid', 'color': Colors.purple},
  ];

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
                'Filters',
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

          // Filter presets
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = currentFilter == filter['name'] ||
                    (currentFilter == null && index == 0);

                return GestureDetector(
                  onTap: () => onFilterChanged?.call(
                    index == 0 ? null : filter['name'] as String,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (filter['color'] as Color).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          Icons.filter,
                          color: filter['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filter['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Intensity slider (only show if filter is selected)
          if (currentFilter != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Intensity',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: intensity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: onIntensityChanged,
                    ),
                  ),
                ),
                Text(
                  '${(intensity * 100).toInt()}%',
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

