import 'dart:math' as math;
import 'dart:ui';

/// Framing rules of thumb for choosing mat borders.

const goldenRatio = 1.6180339887;

/// Uniform border that makes the mat's outer area φ times the artwork's area,
/// so the mat and artwork sit in golden proportion.
///
/// Solves (W + 2w)(H + 2w) = φ·W·H for w.
double goldenMatWidthMm(Size artworkMm) {
  final w = artworkMm.width;
  final h = artworkMm.height;
  final b = 2 * (w + h);
  final c = w * h * (1 - goldenRatio);
  return (-b + math.sqrt(b * b - 16 * c)) / 8;
}

/// The "3:1 rule": a mat border three times the width of the moulding, so the
/// mat, not the frame, leads the eye to the artwork.
double threeToOneMatWidthMm(double faceWidthMm) => faceWidthMm * 3;

/// Gallery convention of a heavier bottom border, which keeps the artwork
/// from looking like it is sliding down (it sits at the "optical centre").
const bottomWeightFactor = 1.25;
