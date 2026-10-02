import 'package:flutter/material.dart';

import '../../models/frame_profile.dart';

/// Horizontally scrolling chips, one per [FrameProfile].
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
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(profile.label),
                selected: profile == selected,
                onSelected: (isSelected) {
                  if (isSelected) onSelected(profile);
                },
                backgroundColor: Colors.black,
                selectedColor: Colors.blueAccent,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.transparent),
                ),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}
