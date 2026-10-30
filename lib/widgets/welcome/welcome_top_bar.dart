import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/user_profile.dart';

/// Brand navigation bar for Screen 1 (Welcome & Discovery / Logged-in Home).
///
/// Renders the `[A] Pick A-Frame` logo mark on the left and the `Log in`
/// action (or signed-in user badge) on the right.
/// The temporary `Catalog` button beside `Log in` has been removed.
class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    super.key,
    required this.onLoginTap,
  });

  final VoidCallback onLoginTap;

  void _showUserAccountSheet(BuildContext context, UserProfile user) {
    final auth = AppScope.of(context).auth;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppPalette.obsidianBlack,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : 'Pick A-Frame Member',
                          style: const TextStyle(
                            color: AppPalette.obsidianBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppPalette.coolSlate,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user.role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.slateTintSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role!.label,
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.midnightSlate,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppPalette.borderLight),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await auth.signOut();
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: AppPalette.obsidianBlack,
                  ),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppPalette.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          // Live Auth State or "Log in" action
          StreamBuilder<UserProfile?>(
            stream: auth.watchUser(),
            initialData: auth.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return InkWell(
                  onTap: () => _showUserAccountSheet(context, user),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.slateTintSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppPalette.midnightSlate.withValues(alpha: 0.3),
                      ),
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
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : user.email,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
