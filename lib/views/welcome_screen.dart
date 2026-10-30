import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../app/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../widgets/welcome/hero_staging_card.dart';
import '../widgets/welcome/how_it_works_section.dart';
import '../widgets/welcome/partner_cta_banner.dart';
import '../widgets/welcome/quick_auth_section.dart';
import '../widgets/welcome/welcome_top_bar.dart';
import 'auth/login_screen.dart';
import 'auth/sign_up_screen.dart';
import 'catalog/catalog_screen.dart';
import 'editor_screen.dart';
import 'exhibit_screen.dart';
import 'orders/my_orders_screen.dart';

/// Screen 1 (`WELCOME & DISCOVERY` / Logged-in Default Home Page):
///
/// - When signed out (`user == null`): renders the unauthenticated Landing Page
///   (with `Log in`, `Already a member? Log in`, and `Register your venue`, no bottom nav bar).
/// - When signed in (`user != null`): transforms into the Default Home Page
///   with the bottom navigation bar (`Home · Catalog · [+] · Exhibit · Orders`).
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => isSignUp
            ? SignUpScreen(initialRole: initialRole)
            : const LoginScreen(),
      ),
    );
  }

  static Route<T> _instantTabRoute<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;

    return StreamBuilder<UserProfile?>(
      stream: auth.watchUser(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isSignedIn = user != null;

        return Scaffold(
          backgroundColor: AppPalette.background,
          body: SafeArea(
            child: Column(
              children: [
                // Sticky Top Brand Header Bar (Catalog button beside Log in removed)
                WelcomeTopBar(
                  onLoginTap: () =>
                      _openAuthAndRoleHook(context, isSignUp: false),
                ),

                // Scrollable Home / Landing Page Body
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4.5,
                              ),
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

                            // Show unauthenticated auth prompt only when signed out
                            if (!isSignedIn) ...[
                              const SizedBox(height: 16),
                              QuickAuthSection(
                                onLoginTap: () => _openAuthAndRoleHook(
                                  context,
                                  isSignUp: false,
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),

                            // How it works (3 steps)
                            const HowItWorksSection(),

                            // Show partner registration CTA only when signed out
                            if (!isSignedIn) ...[
                              const SizedBox(height: 24),
                              PartnerCtaBanner(
                                onRegisterVenueTap: () => _openAuthAndRoleHook(
                                  context,
                                  initialRole: UserRole.frameShopOwner,
                                  isSignUp: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Default Home Page shows the bottom navigation bar once signed in
          bottomNavigationBar: isSignedIn
              ? CatalogBottomNavBar(
                  currentIndex: 0, // Home tab highlighted
                  onTabSelected: (index) {
                    if (index == 0) return;
                    if (index == 1) {
                      Navigator.of(context).push(
                        _instantTabRoute(const CatalogScreen()),
                      );
                      return;
                    }
                    if (index == 2) {
                      Navigator.of(context).push(
                        _instantTabRoute(const ExhibitScreen()),
                      );
                      return;
                    }
                    if (index == 3) {
                      Navigator.of(context).push(
                        _instantTabRoute(const MyOrdersScreen()),
                      );
                      return;
                    }
                  },
                  onCenterAddTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditorScreen(),
                      ),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
