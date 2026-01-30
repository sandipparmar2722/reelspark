import 'package:flutter/material.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/styles.dart';
import '../../editor/image_picker/image_picker_screen.dart';
class PrimaryActionSection extends StatelessWidget {
  const PrimaryActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionCard(
          title: "New Project",
          icon: Icons.movie_creation_outlined,
          color: AppColors.primaryRed,
          onTap: () {
            // Handle New Project action
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ImagePickerScreen();
            },));
          },
        ),
        const SizedBox(width: 12),
        _ActionCard(
          title: "Photo Editing",
          icon: Icons.photo_outlined,
          color: AppColors.primaryPurple,
          onTap: () {
            // Handle Photo Editing action
          },
        ),
      ],
    );
  }
}


class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.cardTitle),
            ],
          ),
        ),
      ),
    );
  }
}
