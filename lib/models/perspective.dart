import 'dart:math' as math;
import 'dart:ui';

/// Four corners of the artwork in a photo, in image pixels. They need not
/// form a rectangle: a painting photographed slightly off-angle appears as a
/// skewed quadrilateral, which [Homography] straightens.
class Quad {
  const Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  /// The whole of an image of [size].
  Quad.full(Size size)
      : topLeft = Offset.zero,
        topRight = Offset(size.width, 0),
        bottomRight = Offset(size.width, size.height),
        bottomLeft = Offset(0, size.height);

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;

  List<Offset> get points => [topLeft, topRight, bottomRight, bottomLeft];

  Quad withPoint(int index, Offset point) {
    final p = [...points]..[index] = point;
    return Quad(p[0], p[1], p[2], p[3]);
  }

  Quad map(Offset Function(Offset) transform) =>
      Quad(transform(topLeft), transform(topRight), transform(bottomRight), transform(bottomLeft));

  /// Size of the straightened result: the longer of each pair of opposite
  /// edges, so no detail is squeezed. (Perspective makes the exact physical
  /// proportions unknowable from one photo; the real size is set in the
  /// editor.)
  Size get straightenedSize => Size(
        math.max((topRight - topLeft).distance, (bottomRight - bottomLeft).distance),
        math.max((bottomLeft - topLeft).distance, (bottomRight - topRight).distance),
      );

  /// Whether the corners still make a sensible, non-twisted shape.
  bool get isConvex {
    final p = points;
    double? sign;
    for (var i = 0; i < 4; i++) {
      final a = p[i];
      final b = p[(i + 1) % 4];
      final c = p[(i + 2) % 4];
      final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
      if (cross.abs() < 1e-9) return false;
      sign ??= cross.sign;
      if (cross.sign != sign) return false;
    }
    return true;
  }
}

/// A projective transform taking points of a [width] x [height] rectangle to
/// the matching corners of a [Quad] (rectangle corner -> quad corner).
class Homography {
  Homography._(this._h);

  factory Homography.rectToQuad(double width, double height, Quad quad) {
    final from = [Offset.zero, Offset(width, 0), Offset(width, height), Offset(0, height)];
    final to = quad.points;

    // Each correspondence (x, y) -> (X, Y) gives two linear equations in the
    // eight unknowns h0..h7 (with h8 fixed at 1).
    final a = List.generate(8, (_) => List.filled(9, 0.0));
    for (var i = 0; i < 4; i++) {
      final x = from[i].dx, y = from[i].dy;
      final bigX = to[i].dx, bigY = to[i].dy;
      a[2 * i]
        ..setAll(0, [x, y, 1, 0, 0, 0, -x * bigX, -y * bigX])
        ..[8] = bigX;
      a[2 * i + 1]
        ..setAll(0, [0, 0, 0, x, y, 1, -x * bigY, -y * bigY])
        ..[8] = bigY;
    }
    return Homography._([..._solve(a), 1.0]);
  }

  /// h0..h8, row by row.
  final List<double> _h;

  List<double> get coefficients => List.unmodifiable(_h);

  Offset apply(Offset p) {
    final w = _h[6] * p.dx + _h[7] * p.dy + _h[8];
    return Offset(
      (_h[0] * p.dx + _h[1] * p.dy + _h[2]) / w,
      (_h[3] * p.dx + _h[4] * p.dy + _h[5]) / w,
    );
  }

  /// Gaussian elimination with partial pivoting on an n x (n+1) system.
  static List<double> _solve(List<List<double>> a) {
    final n = a.length;
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (a[row][col].abs() > a[pivot][col].abs()) pivot = row;
      }
      final tmp = a[col];
      a[col] = a[pivot];
      a[pivot] = tmp;
      if (a[col][col].abs() < 1e-12) {
        throw ArgumentError('Corners are degenerate (three in a line?)');
      }
      for (var row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = a[row][col] / a[col][col];
        for (var k = col; k <= n; k++) {
          a[row][k] -= factor * a[col][k];
        }
      }
    }
    return [for (var i = 0; i < n; i++) a[i][n] / a[i][i]];
  }
}
