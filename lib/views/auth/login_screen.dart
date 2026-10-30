import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import 'auth_navigation.dart';
import 'sign_up_screen.dart';

//login screen: email + password, or Google , links to sign up
//use stateful which mean need to remember things
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  //true while waiting for Firebase, buttons are disabled so nobody taps twice
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //email login, Firebase rejects emails that have no account
  Future<void> _logInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password.');
      return;
    }
    final auth = AppScope.of(context).auth;
    await _signIn(() => auth.signInWithEmail(email: email, password: password));
  }

  //google login, a new google account is registered automatically
  Future<void> _logInWithGoogle() async {
    final auth = AppScope.of(context).auth;
    await _signIn(auth.signInWithGoogle);
  }

  //shared by both buttons: show loading, sign in, then go home or show the error
  Future<void> _signIn(Future<UserProfile> Function() signIn) async {
    setState(() => _busy = true);
    try {
      final profile = await signIn();
      if (!mounted) return;
      openHomeAfterSignIn(context, profile);
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    //scaffold is for a whole screen bone things like the java jframe things
    return Scaffold(
      backgroundColor: AppPalette.background,
      //topbar of the screen (auton including the back button)
      appBar: AppBar(backgroundColor: AppPalette.background, elevation: 0),
      //safe area is for avoid the overlapping about status of phone and the camera(? spot
      body: SafeArea(
        child: Center(
          //make it scrollable, use here becaues the keyboard jump out might cause not enuf height to see
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              //make it same spot
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Log In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.obsidianBlack,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppPalette.coolSlate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Log In
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _logInWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.obsidianBlack,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppPalette.darkCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── or continue with ──
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppPalette.borderLight),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppPalette.coolSlate,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppPalette.borderLight),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sign in with Google
                    GoogleSignInButton(
                      label: 'Sign in with Google',
                      onPressed: _busy ? null : _logInWithGoogle,
                    ),

                    const SizedBox(height: 16),

                    // Don't have an account? Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppPalette.coolSlate,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppPalette.obsidianBlack,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
