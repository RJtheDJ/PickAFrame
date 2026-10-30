import 'package:flutter/material.dart';

import '../../models/units.dart';

/// A slider with a label on the left and its formatted value on the right.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
    this.activeColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double value) format;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF090A0C),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor ?? const Color(0xFF090A0C),
              inactiveTrackColor: const Color(0xFFCBD5E1),
              thumbColor: activeColor ?? const Color(0xFF090A0C),
              overlayColor: const Color(0x14090A0C),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        Container(
          width: 66,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE4EE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            format(value),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF090A0C),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// A slider for a length stored in millimetres, shown in cm or m.
class LengthSlider extends StatelessWidget {
  const LengthSlider({
    super.key,
    required this.label,
    required this.valueMm,
    required this.minMm,
    required this.maxMm,
    required this.onChanged,
    this.stepMm = 1,
    this.activeColor,
  });

  final String label;
  final double valueMm;
  final double minMm;
  final double maxMm;
  final ValueChanged<double> onChanged;

  /// Values snap to multiples of this (1 mm by default).
  final double stepMm;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return LabeledSlider(
      label: label,
      value: valueMm,
      min: minMm,
      max: maxMm,
      activeColor: activeColor,
      format: formatLength,
      onChanged: (mm) => onChanged((mm / stepMm).roundToDouble() * stepMm),
    );
  }
}
