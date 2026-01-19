import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/colors.dart';

enum BottomNavItem { template, home, premium }

class ModernBottomNav extends StatelessWidget {
  final BottomNavItem current;
  final ValueChanged<BottomNavItem> onItemSelected;

  const ModernBottomNav({
    super.key,
    required this.current,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 56 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.view_quilt_outlined,
            label: 'Template',
            active: current == BottomNavItem.template,
            onTap: () => _onTap(BottomNavItem.template),
          ),
          _NavItem(
            icon: Icons.home_filled,
            label: 'Home',
            active: current == BottomNavItem.home,
            onTap: () => _onTap(BottomNavItem.home),
          ),
          _NavItem(
            icon: Icons.workspace_premium_outlined,
            label: 'Premium',
            active: current == BottomNavItem.premium,
            onTap: () => _onTap(BottomNavItem.premium),
          ),
        ],
      ),
    );
  }

  void _onTap(BottomNavItem item) {
    HapticFeedback.selectionClick();
    onItemSelected(item);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedScale(
          scale: active ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: active ? 1.0 : 0.75,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: active
                        ? AppColors.navActive
                        : AppColors.navInactive,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? AppColors.navActive
                          : AppColors.navInactive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
