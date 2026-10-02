import 'frame_profile.dart';

/// A length of frame moulding.
///
/// Later this will come from a vendor catalogue and also carry an id, vendor,
/// rabbet depth and price per metre.
class Moulding {
  const Moulding({required this.profile, required this.faceWidthMm});

  final FrameProfile profile;

  /// Width of the moulding face as seen from the front.
  final double faceWidthMm;

  Moulding copyWith({FrameProfile? profile, double? faceWidthMm}) {
    return Moulding(
      profile: profile ?? this.profile,
      faceWidthMm: faceWidthMm ?? this.faceWidthMm,
    );
  }
}
