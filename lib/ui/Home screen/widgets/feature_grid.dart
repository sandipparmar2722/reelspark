import 'package:flutter/material.dart';
import '../../../core/utils/app_card.dart';
import '../../../core/utils/colors.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      Icons.cut,
      Icons.merge,
      Icons.cut,
      Icons.edit,
      Icons.music_note,
    ];

    final labels = [
      "Trim Video",
      "Merge video",
      "Trim Video",
      "Edit Video",
      "Add Music",
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) {
        return AppCard(
          onTap: () {},
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i], size: 28, color: AppColors.textPrimary),
              const SizedBox(height: 12),
              Text(
                labels[i],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
