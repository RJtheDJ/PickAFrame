import 'package:flutter/material.dart';

/// A labelled, horizontally scrolling row of small colour swatches.
class ColorSwatchRow extends StatelessWidget {
  const ColorSwatchRow({
    super.key,
    required this.label,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF090A0C),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final color in colors)
                  GestureDetector(
                    onTap: () => onSelected(color),
                    child: Container(
                      width: 34,
                      margin: const EdgeInsets.only(right: 10, top: 3, bottom: 3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == selected
                              ? const Color(0xFF090A0C)
                              : const Color(0xFFCBD5E1),
                          width: color == selected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
