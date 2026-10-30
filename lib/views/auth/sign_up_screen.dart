import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/user_profile.dart';
import '../../models/vendor.dart';
import '../../models/venue.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/role_option_card.dart';
import '../../widgets/auth/venue_location_picker.dart';
import 'auth_navigation.dart';
import 'login_screen.dart';

/// Sign-up screen (wireframe 02, "Authentication & Role Setup"):
/// 02A credentials (Google or email), 02B role, and 02C venue for gallery and
/// frame shop owners.
///
/// With [signedInProfile] the user is already signed in but has no role yet
/// (e.g. a first Google log-in), so 02A only shows who they are.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.initialRole, this.signedInProfile});

  /// Pre-selected role, e.g. Frame Shop Owner from "Register your venue".
  final UserRole? initialRole;
  final UserProfile? signedInProfile;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _minPasswordLength = 6;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _unitController = TextEditingController();
  final _hoursController = TextEditingController();

  late UserRole? _role = widget.initialRole;
  PickedLocation? _location;
  bool _consented = false;
  bool _obscurePassword = true;
  bool _busy = false;

  bool get _isSignedIn => widget.signedInProfile != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _unitController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  /// The first problem with the form, or null when it can be submitted.
  /// Google sign-up skips the credential checks.
  String? _validate({required bool checkCredentials}) {
    if (checkCredentials && !_isSignedIn) {
      if (_nameController.text.trim().isEmpty) return 'Enter your name.';
      if (!_emailController.text.contains('@')) return 'Enter a valid email.';
      if (_passwordController.text.length < _minPasswordLength) {
        return 'Password must be at least $_minPasswordLength characters.';
      }
    }
    if (!_consented) return 'Please agree to the Service Terms & PDPA Notice.';
    final role = _role;
    if (role == null) return 'Choose your operational profile.';
    if (role.needsLocation) {
      if (_location == null) return 'Pin your venue on the map.';
      if (_businessNameController.text.trim().isEmpty) {
        return 'Enter your registered business name.';
      }
    }
    return null;
  }

  Future<void> _createAccount() async {
    final error = _validate(checkCredentials: true);
    if (error != null) return _showError(error);
    final deps = AppScope.of(context);
    await _submit(() async {
      if (!_isSignedIn) {
        await deps.auth.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }
      return _saveRole(deps);
    });
  }

  /// Role and consent come first, then Google, then the role is saved.
  /// An existing account that already has a role just signs in.
  Future<void> _continueWithGoogle() async {
    final error = _validate(checkCredentials: false);
    if (error != null) return _showError(error);
    final deps = AppScope.of(context);
    await _submit(() async {
      final profile = await deps.auth.signInWithGoogle();
      return profile.role != null ? profile : _saveRole(deps);
    });
  }

  /// Saves the role and venue; frame shops also get a directory listing.
  Future<UserProfile> _saveRole(AppDependencies deps) async {
    final role = _role!;
    final location = _location;
    final venue = role.needsLocation && location != null
        ? Venue(
            name: _businessNameController.text.trim(),
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude,
            unit: _optional(_unitController),
            openingHours: _optional(_hoursController),
          )
        : null;

    final profile = await deps.auth.setRole(role, venue: venue);
    if (role == UserRole.frameShopOwner && venue != null) {
      await deps.vendors.saveVendor(Vendor(
        id: profile.uid,
        ownerUid: profile.uid,
        name: venue.name,
        address: venue.address,
        latitude: venue.latitude,
        longitude: venue.longitude,
      ));
    }
    return profile;
  }

  Future<void> _submit(Future<UserProfile> Function() action) async {
    setState(() => _busy = true);
    try {
      final profile = await action();
      if (!mounted) return;
      openHomeAfterSignIn(context, profile);
    } on AuthException catch (e) {
      _showError(e.message);
    } on Exception catch (e) {
      _showError('Could not save your profile: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _selectRole(UserRole role) {
    setState(() {
      _role = role;
      if (!role.needsLocation) _location = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    return Scaffold(
      backgroundColor: AppPalette.surfaceLight,
      appBar: AppBar(backgroundColor: AppPalette.surfaceLight, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Authentication & Role Setup',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your primary role to calibrate your workspace. '
                    'You can switch or add another role later.',
                    style: TextStyle(
                      color: AppPalette.coolSlate,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    label: '02A · ACCESS CREDENTIALS',
                    trailing: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppPalette.coolSlate,
                    ),
                    child: _buildCredentials(),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('02B · OPERATIONAL PROFILE'),
                  const SizedBox(height: 10),
                  for (final option in UserRole.values) ...[
                    RoleOptionCard(
                      role: option,
                      selected: role == option,
                      onTap: () => _selectRole(option),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (role != null && role.needsLocation) ...[
                    const SizedBox(height: 10),
                    _SectionCard(
                      label: '02C · VENUE DIRECTORY VERIFICATION',
                      trailing: const _SectionLabel('KLANG VALLEY REGION'),
                      child: _buildVenue(role),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  if (!_isSignedIn) _buildLogInLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentials() {
    final signedIn = widget.signedInProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (signedIn != null)
          Text(
            'Signed in as ${signedIn.email}. Finish your role setup below.',
            style: const TextStyle(color: AppPalette.coolSlate, fontSize: 13.5),
          )
        else ...[
          GoogleSignInButton(
            label: 'Continue with Google',
            onPressed: _busy ? null : _continueWithGoogle,
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Full name',
            controller: _nameController,
            hintText: 'Your name',
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Work email',
            controller: _emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            suffixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: AppPalette.coolSlate,
            ),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Password',
            controller: _passwordController,
            hintText: 'At least $_minPasswordLength characters',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppPalette.coolSlate,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _consented,
          onChanged: (value) => setState(() => _consented = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: AppPalette.obsidianBlack,
          title: const Text(
            'I agree to the Pick A-Frame Service Terms & PDPA Regulatory Notice.',
            style: TextStyle(color: AppPalette.coolSlate, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildVenue(UserRole role) {
    final place =
        role == UserRole.galleryOwner ? 'gallery' : 'workshop';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where is your $place?',
          style: const TextStyle(
            color: AppPalette.obsidianBlack,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Clients and trade fabricators locate your verification badge via '
          'our live coordinate directory.',
          style: TextStyle(color: AppPalette.coolSlate, fontSize: 13),
        ),
        const SizedBox(height: 14),
        VenueLocationPicker(
          onChanged: (location) => setState(() => _location = location),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Registered business name',
          controller: _businessNameController,
          hintText: 'e.g. Sareng Art Gallery & Advisory',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Unit / suite',
                controller: _unitController,
                hintText: 'Level 2, Suite B',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Operating hours',
                controller: _hoursController,
                hintText: 'Tue-Sun 11:00-19:00',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _busy ? null : _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.obsidianBlack,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppPalette.darkCharcoal,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isSignedIn ? 'Finish Setup' : 'Create Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildLogInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(fontSize: 12.5, color: AppPalette.coolSlate),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          child: const Text(
            'Log In',
            style: TextStyle(
              color: AppPalette.obsidianBlack,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

/// White card with a small uppercase label, used for 02A and 02C.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _SectionLabel(label)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.monoStyle(
        fontSize: 11,
        color: AppPalette.coolSlate,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppPalette.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR MANUAL ENTRY',
            style: AppTheme.monoStyle(fontSize: 10.5, color: AppPalette.coolSlate),
          ),
        ),
        const Expanded(child: Divider(color: AppPalette.borderLight)),
      ],
    );
  }
}
