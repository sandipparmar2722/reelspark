/// Model for filter/effect clip
///
/// This model allows:
/// - Defining filter type and parameters
/// - Positioning filter on timeline
/// - Future: multiple filters, intensity, blending
class FilterClip {
  /// Unique identifier
  final String id;

  /// Filter type name
  final String filterType;

  /// Where this filter starts on the timeline (in seconds)
  double startTime;

  /// Where this filter ends on the timeline (in seconds)
  double endTime;

  /// Filter intensity (0.0 to 1.0)
  double intensity;

  FilterClip({
    required this.id,
    required this.filterType,
    required this.startTime,
    required this.endTime,
    this.intensity = 1.0,
  });

  /// The duration of this filter clip
  double get duration => endTime - startTime;

  /// Check if a timeline position is within this filter's range
  bool isActiveAt(double time) {
    return time >= startTime && time <= endTime;
  }

  /// Create a copy with modified values
  FilterClip copyWith({
    String? id,
    String? filterType,
    double? startTime,
    double? endTime,
    double? intensity,
  }) {
    return FilterClip(
      id: id ?? this.id,
      filterType: filterType ?? this.filterType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      intensity: intensity ?? this.intensity,
    );
  }

  /// Minimum allowed duration (in seconds)
  static const double minDuration = 0.1;

  @override
  String toString() {
    return 'FilterClip(id: $id, type: $filterType, startTime: $startTime, endTime: $endTime)';
  }
}

