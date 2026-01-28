
import 'package:reelspark/ui/editor/editor.dart';

class TransitionPicker extends StatelessWidget {
  final Function(ClipTransition) onSelect;

  const TransitionPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          _item('Fade', ClipTransitionType.fade),
          _item('Slide', ClipTransitionType.slideLeft),
          _item('Zoom', ClipTransitionType.zoom),
        ],
      ),
    );
  }

  Widget _item(String label, ClipTransitionType type) {
    return GestureDetector(
      onTap: () => onSelect(
        ClipTransition(type: type, duration: 0.4),
      ),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.black,
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
