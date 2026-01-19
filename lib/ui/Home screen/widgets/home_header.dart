import 'package:flutter/material.dart';
import '../../../core/utils/styles.dart';
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.movie_creation_outlined, size: 28),
        const SizedBox(width: 8),
        const Text("Video Editing ", style: AppTextStyles.title),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }
}
