import '../../templates/templates.dart';
import 'package:reelspark/ui/editor/editor.dart';
class EffectTimeline extends StatelessWidget {
  final List<EffectClip> effects;
  final double totalDuration;
  final Function(EffectClip) onSelect;
  final Function(EffectClip, double, double) onMove;

  const EffectTimeline({
    super.key,
    required this.effects,
    required this.totalDuration,
    required this.onSelect,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        children: effects.map((clip) {
          final left =
              clip.startTime * TimelineContainer.pixelsPerSecond;
          final width =
              clip.duration * TimelineContainer.pixelsPerSecond;

          return Positioned(
            left: left,
            width: width,
            top: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: () => onSelect(clip),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    clip.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
