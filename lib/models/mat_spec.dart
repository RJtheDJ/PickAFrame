import 'dart:ui';

/// The mat board around the artwork, with an independent border on each side.
class MatSpec {
  const MatSpec({
    required this.topMm,
    required this.bottomMm,
    required this.leftMm,
    required this.rightMm,
    this.color = defaultColor,
  });

  /// The same border on all four sides.
  const MatSpec.uniform(double mm, {Color color = defaultColor})
      : this(topMm: mm, bottomMm: mm, leftMm: mm, rightMm: mm, color: color);

  static const defaultColor = Color(0xFFF5F5F0);

  final double topMm;
  final double bottomMm;
  final double leftMm;
  final double rightMm;
  final Color color;

  double get horizontalMm => leftMm + rightMm;
  double get verticalMm => topMm + bottomMm;

  MatSpec copyWith({
    double? topMm,
    double? bottomMm,
    double? leftMm,
    double? rightMm,
    Color? color,
  }) {
    return MatSpec(
      topMm: topMm ?? this.topMm,
      bottomMm: bottomMm ?? this.bottomMm,
      leftMm: leftMm ?? this.leftMm,
      rightMm: rightMm ?? this.rightMm,
      color: color ?? this.color,
    );
  }
}
