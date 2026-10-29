import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/user_profile.dart';

/// One selectable role card in sign-up section 02B (Operational Profile).
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (subtitle, description, badge) = switch (role) {
      UserRole.artist => (
          'INDIVIDUAL CREATOR',
          'Frame my work, preview on simulated gallery walls, and share '
              'export sheets with curators.',
          '3 Steps · No address',
        ),
      UserRole.galleryOwner => (
          'COMMERCIAL EXHIBITOR',
          'Plan exhibitions, frame works in bulk, coordinate consignments, '
              'and manage architectural budget specs.',
          'Venue Required',
        ),
      UserRole.frameShopOwner => (
          'PRODUCTION FABRICATOR',
          'Publish moulding profiles, receive verified architectural cut '
              'lists, and dispatch completed orders.',
          'Workshop Required',
        ),
    };

    return Material(
      color: selected ? AppPalette.slateTintSurface : AppPalette.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppPalette.midnightSlate : AppPalette.borderLight,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppPalette.obsidianBlack : AppPalette.mutedZinc,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role.label,
                            style: const TextStyle(
                              color: AppPalette.obsidianBlack,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _Badge(
                          text: badge,
                          icon: role.needsLocation
                              ? Icons.location_on_outlined
                              : null,
                          dark: selected && role.needsLocation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.monoStyle(
                        fontSize: 10.5,
                        color: AppPalette.coolSlate,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppPalette.coolSlate,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon, this.dark = false});

  final String text;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : AppPalette.coolSlate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? AppPalette.obsidianBlack : AppPalette.slateTintSurface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTheme.monoStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
