import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../app/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/welcome/hero_staging_card.dart';
import '../widgets/welcome/how_it_works_section.dart';
import '../widgets/welcome/partner_cta_banner.dart';
import '../widgets/welcome/quick_auth_section.dart';
import '../widgets/welcome/welcome_top_bar.dart';
import 'catalog/catalog_screen.dart';

/// Screen 1 (`SPEC // S1 · WELCOME & DISCOVERY`): Landing Page for Pick A-Frame.
///
/// Built according to the wireframe specification and the 5-color palette
/// (`#1E2229`, `#090A0C`, `#2C3E50`, `#4B5563`, `#71717A`) on a clean light
/// architectural canvas (`#FFFFFF` / `#F8FAFC`).
///
/// Customers can immediately test uploading and cropping their artwork inside
/// the 1:1 Real-Time Staging Box before signing in, without modifying or
/// navigating away to `EditorScreen`.
///
/// When your teammate finishes the Sign-In & Role Setup screen (`SPEC 02`),
/// pass their route builder into [onNavigateToAuth] or replace
/// `_openAuthAndRoleHook`.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onNavigateToAuth,
  });

  /// Optional callback hook for navigating to `SPEC 02 // Authentication & Role Setup`.
  final void Function(BuildContext context, {UserRole? initialRole, bool isSignUp})?
      onNavigateToAuth;

  void _openAuthAndRoleHook(
    BuildContext context, {
    UserRole? initialRole,
    bool isSignUp = false,
  }) {
    if (onNavigateToAuth != null) {
      onNavigateToAuth!(context, initialRole: initialRole, isSignUp: isSignUp);
      return;
    }

    final auth = AppScope.of(context).auth;
    final currentUser = auth.currentUser;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                currentUser != null
                    ? 'Signed in as ${currentUser.displayName.isNotEmpty ? currentUser.displayName : currentUser.email}'
                    : (isSignUp ? 'Sign up with Email & Role Setup' : 'Authentication & Role Setup'),
                style: const TextStyle(
                  color: AppPalette.obsidianBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                initialRole != null
                    ? 'Pre-selected operational profile: ${initialRole.label}. Ready to connect to your teammate\'s Sign-In screen.'
                    : 'Navigation hook ready for Authentication & Role Setup screen.',
                style: const TextStyle(
                  color: AppPalette.coolSlate,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              if (currentUser != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.obsidianBlack,
                    side: const BorderSide(color: AppPalette.coolSlate),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.obsidianBlack,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Top Spec & Brand Header Bar (without EN | BM switcher)
            WelcomeTopBar(
              onLoginTap: () => _openAuthAndRoleHook(context, isSignUp: false),
              onCatalogTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CatalogScreen()),
                );
              },
            ),

            // Scrollable Landing Page Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ● PRECISION STAGING SYSTEM Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: AppPalette.slateTintSurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppPalette.obsidianBlack,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'PRECISION STAGING SYSTEM',
                                style: AppTheme.monoStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.midnightSlate,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Hero Headline: Frame it. Hang it.\nGet it made.
                        const Text(
                          'Frame it. Hang it.\nGet it made.',
                          style: TextStyle(
                            color: AppPalette.obsidianBlack,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.14,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Hero Subtitle
                        const Text(
                          'Preview custom framing on your art before a single cut is made. Calibrated for Kuala Lumpur workshops & galleries.',
                          style: TextStyle(
                            color: AppPalette.coolSlate,
                            fontSize: 13,
                            height: 1.42,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Interactive 1:1 Real-Time Artwork Staging Card
                        const HeroStagingCard(),

                        const SizedBox(height: 16),

                        // Continue with Google / Sign up with email / Log in
                        QuickAuthSection(
                          onEmailSignUpTap: () =>
                              _openAuthAndRoleHook(context, isSignUp: true),
                          onLoginTap: () =>
                              _openAuthAndRoleHook(context, isSignUp: false),
                        ),

                        const SizedBox(height: 22),

                        // How it works (3 steps)
                        const HowItWorksSection(),

                        const SizedBox(height: 24),

                        // For galleries & frame shops [ Register your venue ]
                        PartnerCtaBanner(
                          onRegisterVenueTap: () => _openAuthAndRoleHook(
                            context,
                            initialRole: UserRole.frameShopOwner,
                            isSignUp: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
