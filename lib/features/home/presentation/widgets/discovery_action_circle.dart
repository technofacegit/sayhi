import 'package:flutter/material.dart';

/// Circular action used on the home swipe deck and discovery profile (same look).
class DiscoveryActionCircle extends StatelessWidget {
  const DiscoveryActionCircle({
    super.key,
    required this.color,
    required this.icon,
    this.onTap,
    this.emphasized = false,
  });

  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  /// Stronger fill when this action is the active/toggled state (e.g. profile detail).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final bgAlpha = emphasized ? 0.28 : 0.15;
    return Material(
      color: color.withValues(alpha: bgAlpha),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}
