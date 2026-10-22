import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../repositories/auth_repository.dart';

/// Authentication CTA buttons below the 1:1 Staging Box on the Landing Page:
/// - `Continue with Google` (wired directly to `AppScope.of(context).auth.signInWithGoogle()`)
/// - `Sign up with email` (wired to the Sign-In / Role Setup hook)
/// - `Already a member? Log in`
class QuickAuthSection extends StatefulWidget {
  const QuickAuthSection({
    super.key,
    required this.onEmailSignUpTap,
    required this.onLoginTap,
  });

  final VoidCallback onEmailSignUpTap;
  final VoidCallback onLoginTap;

  @override
  State<QuickAuthSection> createState() => _QuickAuthSectionState();
}

class _QuickAuthSectionState extends State<QuickAuthSection> {
  bool _signingInWithGoogle = false;

  Future<void> _handleGoogleSignIn() async {
    final auth = AppScope.of(context).auth;
    setState(() => _signingInWithGoogle = true);
    try {
      final profile = await auth.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signed in as ${profile.displayName.isNotEmpty ? profile.displayName : profile.email}',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _signingInWithGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Continue with Google
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: _signingInWithGoogle ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppPalette.background,
              foregroundColor: AppPalette.obsidianBlack,
              side: const BorderSide(color: AppPalette.coolSlate, width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: _signingInWithGoogle
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.obsidianBlack,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleLogoMark(size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: AppPalette.obsidianBlack,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Sign up with email
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: widget.onEmailSignUpTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppPalette.background,
              foregroundColor: AppPalette.obsidianBlack,
              side: const BorderSide(color: AppPalette.coolSlate, width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: AppPalette.coolSlate,
                ),
                SizedBox(width: 10),
                Text(
                  'Sign up with email',
                  style: TextStyle(
                    color: AppPalette.obsidianBlack,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Already a member? Log in
        Center(
          child: InkWell(
            onTap: widget.onLoginTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppPalette.mutedZinc,
                    decoration: TextDecoration.underline,
                    decorationColor: AppPalette.mutedZinc,
                  ),
                  children: [
                    TextSpan(text: 'Already a member? '),
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(
                        color: AppPalette.obsidianBlack,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: AppPalette.obsidianBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom vector-painted Google 'G' mark matching the wireframe button.
class _GoogleLogoMark extends StatelessWidget {
  const _GoogleLogoMark({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.21;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.65, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.35, 1.55, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.75, 1.60, false, paint);

    // Blue right arc + crossbar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.15, 0.90, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.41,
        size.width * 0.45,
        stroke * 0.92,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
