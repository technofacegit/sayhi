import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onNavTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final l10n = context.l10n;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      bottomNavigationBar: keyboardOpen
          ? null
          : BottomAppBar(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    selected: navigationShell.currentIndex == 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: l10n.navHome,
                    onTap: () => _onNavTap(context, 0),
                  ),
                  _NavItem(
                    selected: navigationShell.currentIndex == 1,
                    icon: Icons.place_outlined,
                    selectedIcon: Icons.place_rounded,
                    label: l10n.navZones,
                    onTap: () => _onNavTap(context, 1),
                  ),
                  _NavItem(
                    selected: false,
                    icon: Icons.waving_hand_outlined,
                    selectedIcon: Icons.waving_hand_rounded,
                    label: l10n.navSayHi,
                    onTap: () => context.go(AppRouter.qrJoinPath),
                  ),
                  _NavItem(
                    selected: navigationShell.currentIndex == 2,
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: l10n.navChats,
                    onTap: () => _onNavTap(context, 2),
                  ),
                  _NavItem(
                    selected: navigationShell.currentIndex == 3,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: l10n.navProfile,
                    onTap: () => _onNavTap(context, 3),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
