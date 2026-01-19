import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.onTap, this.backgroundColor, this.padding});

  @override
  Widget build(BuildContext context) {
    final Color surface = backgroundColor ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000), // slightly darker lift
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x12000000), // ambient spread
                  blurRadius: 26,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: padding != null ? Padding(padding: padding!, child: child) : child,
          ),
        ),
      ),
    );
  }
}
