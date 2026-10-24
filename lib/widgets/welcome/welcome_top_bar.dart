import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/user_profile.dart';

/// Brand navigation bar for Screen 1 (Welcome & Discovery).
///
/// Renders the `[A] Pick A-Frame` logo mark on the left and the `Log in`
/// action (or signed-in user badge) on the right.
class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    super.key,
    required this.onLoginTap,
    this.onCatalogTap,
  });

  final VoidCallback onLoginTap;
  final VoidCallback? onCatalogTap;

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(
          bottom: BorderSide(color: AppPalette.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // [A] Logo mark
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppPalette.background,
              border: Border.all(color: AppPalette.obsidianBlack, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: const Text(
              'A',
              style: TextStyle(
                color: AppPalette.obsidianBlack,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Brand title & subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick A-Frame',
                style: TextStyle(
                  color: AppPalette.obsidianBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              Text(
                'PRECISION FRAMING',
                style: AppTheme.monoStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.mutedZinc,
                  letterSpacing: 1.1,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onCatalogTap != null) ...[
            OutlinedButton.icon(
              onPressed: onCatalogTap,
              icon: const Icon(Icons.grid_view_rounded, size: 13),
              label: Text(
                'Catalog',
                style: AppTheme.monoStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.obsidianBlack,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppPalette.slateTintSurface,
                foregroundColor: AppPalette.obsidianBlack,
                side: const BorderSide(color: AppPalette.borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Live Auth State or "Log in" action
          StreamBuilder<UserProfile?>(
            stream: auth.watchUser(),
            initialData: auth.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return InkWell(
                  onTap: onLoginTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppPalette.slateTintSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppPalette.midnightSlate.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppPalette.midnightSlate,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.displayName.isNotEmpty ? user.displayName : user.email,
                          style: const TextStyle(
                            color: AppPalette.midnightSlate,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return TextButton(
                onPressed: onLoginTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppPalette.obsidianBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: AppPalette.obsidianBlack,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
