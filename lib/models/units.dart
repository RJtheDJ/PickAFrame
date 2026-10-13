import 'dart:ui';

// Lengths are stored in millimetres (precise enough for cutting mats and
// mouldings) but shown in centimetres, or metres for large sizes.

/// "4.5 cm", "40 cm", or "1.25 m" from 1000 mm up.
String formatLength(double mm) {
  if (mm.abs() >= 1000) return '${(mm / 1000).toStringAsFixed(2)} m';
  return '${_trimmed(mm / 10)} cm';
}

/// "40 × 30 cm", or "1.20 × 0.90 m" when either side reaches a metre.
String formatSize(Size mm) {
  if (mm.longestSide >= 1000) {
    return '${(mm.width / 1000).toStringAsFixed(2)} × ${(mm.height / 1000).toStringAsFixed(2)} m';
  }
  return '${_trimmed(mm.width / 10)} × ${_trimmed(mm.height / 10)} cm';
}

/// One decimal place, dropping a trailing ".0".
String _trimmed(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
