import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Bottom navigation bar shown in the Catalog wireframe (`Home`, `Catalog`, `[+]`, `Exhibit`, `Orders`).
class CatalogBottomNavBar extends StatelessWidget {
  const CatalogBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterAddTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(
          top: BorderSide(color: AppPalette.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.grid_view_outlined,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _BottomNavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Catalog',
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              // Center Dark [ + ] Action Button
              SizedBox(
                width: 42,
                height: 42,
                child: ElevatedButton(
                  onPressed: onCenterAddTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.obsidianBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                ),
              ),
              _BottomNavItem(
                icon: Icons.museum_outlined,
                label: 'Exhibit',
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _BottomNavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                selected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppPalette.obsidianBlack : AppPalette.mutedZinc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTheme.monoStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
