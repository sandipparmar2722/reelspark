import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/navigation/nav_bloc.dart';
import '../../blocs/navigation/nav_contract.dart';
import '../Home screen/Home_screen.dart';
import '../subscription.dart';
import '../bottom_nav/modern_bottom_nav.dart';
import '../templates/screens/templates_home_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  /// Tabs that have been opened at least once
  final Set<BottomNavItem> _loadedTabs = {BottomNavItem.home};

  /// Keep widget instances to preserve state
  final Map<BottomNavItem, Widget> _tabCache = {};

  @override
  void initState() {
    super.initState();

    /// 🔥 Background prefetch AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchTabs();
    });
  }

  void _prefetchTabs() async {
    // Delay a bit so HomeScreen feels instant
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    /// Example: prefetch lightweight data only
    // context.read<InfoBloc>().add(PrefetchEvent());
    // context.read<SubscriptionBloc>().add(PrefetchEvent());
  }

  Widget _buildTab(BottomNavItem tab) {
    return _tabCache.putIfAbsent(tab, () {
      switch (tab) {
        case BottomNavItem.template:
          return const TemplatesHomeScreen();
        case BottomNavItem.home:
          return const HomeScreen();
        case BottomNavItem.premium:
          return const subscription();
      }
    });
  }

  int _index(BottomNavItem tab) {
    switch (tab) {
      case BottomNavItem.template:
        return 0;
      case BottomNavItem.home:
        return 1;
      case BottomNavItem.premium: 
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavData>(
      builder: (context, state) {
        _loadedTabs.add(state.currentTab);

        return Scaffold(
          body: IndexedStack(
            index: _index(state.currentTab),
            children: BottomNavItem.values.map((tab) {
              if (_loadedTabs.contains(tab)) {
                return _buildTab(tab);
              }

              /// 🦴 Skeleton placeholder (cheap)
              return const _TabSkeleton();
            }).toList(),
          ),

          bottomNavigationBar: ModernBottomNav(
            current: state.currentTab,
            onItemSelected: (tab) {
              HapticFeedback.selectionClick();
              context.read<NavBloc>().add(ChangeTabEvent(tab));
            },
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// SKELETON PLACEHOLDER (PER TAB)
/// ------------------------------------------------------------
class _TabSkeleton extends StatelessWidget {
  const _TabSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
              (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
