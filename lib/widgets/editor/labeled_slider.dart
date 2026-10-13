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
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            format(value),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
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
