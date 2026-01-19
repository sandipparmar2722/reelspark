import 'package:flutter/material.dart';

import '../applicationinformation/info.dart';
import '../bottom_nav/modern_bottom_nav.dart';

import '../common/app_gradient_container.dart';
import '../subscription.dart';
import 'widgets/home_header.dart';
import 'widgets/primary_action_section.dart';
import 'widgets/feature_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBgContainer(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 20),
            const PrimaryActionSection(),
            const SizedBox(height: 24),
            const Expanded(
              child: FeatureGrid(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
