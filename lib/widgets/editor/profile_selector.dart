import 'package:flutter/material.dart';

import '../../models/frame_profile.dart';

/// Horizontally scrolling architectural pills, one per [FrameProfile].
class ProfileSelector extends StatelessWidget {
  const ProfileSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FrameProfile selected;
  final ValueChanged<FrameProfile> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final profile in FrameProfile.values)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: GestureDetector(
                onTap: () => onSelected(profile),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: profile == selected
                        ? const Color(0xFF090A0C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: profile == selected
                          ? const Color(0xFF090A0C)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    profile.label,
                    style: TextStyle(
                      color: profile == selected
                          ? Colors.white
                          : const Color(0xFF090A0C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
