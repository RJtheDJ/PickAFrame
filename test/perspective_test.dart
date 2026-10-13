import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/perspective.dart';

void expectNear(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-6));
  expect(actual.dy, closeTo(expected.dy, 1e-6));
}

void main() {
  // A painting photographed from slightly to the left: its right edge looks
  // shorter than its left.
  const skewed = Quad(Offset(100, 80), Offset(900, 140), Offset(880, 620), Offset(120, 700));

  group('Homography.rectToQuad', () {
    test('maps the rectangle corners onto the quad corners', () {
      final h = Homography.rectToQuad(800, 600, skewed);
      expectNear(h.apply(Offset.zero), skewed.topLeft);
      expectNear(h.apply(const Offset(800, 0)), skewed.topRight);
      expectNear(h.apply(const Offset(800, 600)), skewed.bottomRight);
      expectNear(h.apply(const Offset(0, 600)), skewed.bottomLeft);
    });

    test('a rectangle to an equal rectangle is a plain offset', () {
      const quad = Quad(Offset(10, 20), Offset(110, 20), Offset(110, 70), Offset(10, 70));
      final h = Homography.rectToQuad(100, 50, quad);
      expectNear(h.apply(const Offset(30, 40)), const Offset(40, 60));
    });

    test('straight lines stay straight (midpoints of edges land on edges)', () {
      final h = Homography.rectToQuad(800, 600, skewed);
      final mid = h.apply(const Offset(400, 0));
      // Collinear with the top edge: zero cross product.
      final a = skewed.topRight - skewed.topLeft;
      final b = mid - skewed.topLeft;
      expect(a.dx * b.dy - a.dy * b.dx, closeTo(0, 1e-6));
    });

    test('rejects corners bunched into a line', () {
      const flat = Quad(Offset(0, 0), Offset(10, 0), Offset(20, 0), Offset(30, 0));
      expect(() => Homography.rectToQuad(10, 10, flat), throwsArgumentError);
    });
  });

  group('Quad', () {
    test('straightened size uses the longer of opposite edges', () {
      // Top edge 100 wide, bottom 80; right edge vertical (50), left slanted.
      const quad = Quad(Offset(0, 0), Offset(100, 0), Offset(100, 50), Offset(20, 50));
      expect(quad.straightenedSize.width, 100);
      expect(quad.straightenedSize.height, closeTo(53.85, 0.01)); // the slanted left edge
    });

    test('a twisted quad is not convex', () {
      const twisted = Quad(Offset(0, 0), Offset(100, 100), Offset(100, 0), Offset(0, 100));
      expect(twisted.isConvex, isFalse);
      expect(skewed.isConvex, isTrue);
    });
  });
}
