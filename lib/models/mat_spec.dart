import 'dart:ui';

enum MatSide { top, bottom, left, right }

/// How the artwork is presented inside the frame.
enum MountStyle {
  /// A single mat board with a bevelled window.
  flat('Flat'),

  /// A second mat underneath, showing as a thin band ("reveal") around the art.
  doubleMat('Double'),

  /// The artwork sits on top of the board, casting a shadow; no window.
  float('Float');

  const MountStyle(this.label);

  final String label;
}

/// The mat board around the artwork.
///
/// Each border is measured from the frame's inner edge to the artwork, so
/// switching mount style never changes the overall frame size. In a double
/// mat, the [revealMm] band of the inner mat sits inside those borders.
class MatSpec {
  const MatSpec({
    required this.topMm,
    required this.bottomMm,
    required this.leftMm,
    required this.rightMm,
    this.color = defaultColor,
    this.coreColor = defaultCoreColor,
    this.style = MountStyle.flat,
    this.innerColor = defaultInnerColor,
    this.revealMm = 6,
  });

  /// The same border on all four sides.
  const MatSpec.uniform(double mm)
      : this(topMm: mm, bottomMm: mm, leftMm: mm, rightMm: mm);

  static const defaultColor = Color(0xFFF5F5F0);
  static const defaultCoreColor = Color(0xFFFFFFFF);
  static const defaultInnerColor = Color(0xFF3A3A3A);

  /// Visible width of the 45° cut through the board, seen from the front.
  static const bevelMm = 2.0;

  final double topMm;
  final double bottomMm;
  final double leftMm;
  final double rightMm;

  /// Face colour of the (top) mat board.
  final Color color;

  /// Colour of the board's core, which shows on the bevel cut.
  final Color coreColor;

  final MountStyle style;

  /// Face colour of the lower mat in a double mat.
  final Color innerColor;

  /// How much of the lower mat shows around the artwork in a double mat.
  final double revealMm;

  double get horizontalMm => leftMm + rightMm;
  double get verticalMm => topMm + bottomMm;

  bool get isUniform =>
      topMm == bottomMm && topMm == leftMm && topMm == rightMm;

  double side(MatSide side) => switch (side) {
        MatSide.top => topMm,
        MatSide.bottom => bottomMm,
        MatSide.left => leftMm,
        MatSide.right => rightMm,
      };

  MatSpec withSide(MatSide side, double mm) => switch (side) {
        MatSide.top => copyWith(topMm: mm),
        MatSide.bottom => copyWith(bottomMm: mm),
        MatSide.left => copyWith(leftMm: mm),
        MatSide.right => copyWith(rightMm: mm),
      };

  MatSpec withAllSides(double mm) =>
      copyWith(topMm: mm, bottomMm: mm, leftMm: mm, rightMm: mm);

  MatSpec copyWith({
    double? topMm,
    double? bottomMm,
    double? leftMm,
    double? rightMm,
    Color? color,
    Color? coreColor,
    MountStyle? style,
    Color? innerColor,
    double? revealMm,
  }) {
    return MatSpec(
      topMm: topMm ?? this.topMm,
      bottomMm: bottomMm ?? this.bottomMm,
      leftMm: leftMm ?? this.leftMm,
      rightMm: rightMm ?? this.rightMm,
      color: color ?? this.color,
      coreColor: coreColor ?? this.coreColor,
      style: style ?? this.style,
      innerColor: innerColor ?? this.innerColor,
      revealMm: revealMm ?? this.revealMm,
    );
  }
}
