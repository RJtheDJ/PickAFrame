/// Cross-section shape of a moulding. Drives the lighting overlay in
/// `GenerativeFramePainter`.
enum FrameProfile {
  flat('Flat'),
  slope('Slope'),
  scoop('Scoop'),
  beveled('Beveled'),
  curve('Curve'),
  stepped('Stepped'),
  reverseSlope('Reverse Slope'),
  triangular('Triangular');

  const FrameProfile(this.label);

  final String label;
}
