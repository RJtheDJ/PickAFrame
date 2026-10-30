import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// `Already a member? Log in` link below the 1:1 Staging Box on the Landing Page.
class QuickAuthSection extends StatelessWidget {
  const QuickAuthSection({
    super.key,
    required this.onLoginTap,
  });

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //Already a member? Log in
        Center(
          child: InkWell(
            onTap: onLoginTap,
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
