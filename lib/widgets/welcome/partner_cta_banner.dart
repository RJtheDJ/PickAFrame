import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// "For galleries & frame shops" partner registration banner (`[ Register your venue ]`).
class PartnerCtaBanner extends StatelessWidget {
  const PartnerCtaBanner({
    super.key,
    required this.onRegisterVenueTap,
  });

  final VoidCallback onRegisterVenueTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.slateTintSurface,
        border: Border.all(color: AppPalette.borderLight, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: AppPalette.obsidianBlack,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'For galleries & frame shops',
                      style: TextStyle(
                        color: AppPalette.obsidianBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Receive structured, locked millimeter specs. List your workshop in the KL directory and manage batch orders without chat errors.',
                      style: TextStyle(
                        color: AppPalette.coolSlate,
                        fontSize: 11.5,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onRegisterVenueTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppPalette.background,
                foregroundColor: AppPalette.obsidianBlack,
                side: const BorderSide(color: AppPalette.darkCharcoal, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(
                '[ Register your venue ]',
                style: AppTheme.monoStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.obsidianBlack,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
