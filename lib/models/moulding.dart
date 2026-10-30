import 'frame_profile.dart';

/// A length of frame moulding.
class Moulding {
  const Moulding({required this.profile, required this.faceWidthMm, this.catalogId});

  final FrameProfile profile;

  /// Width of the moulding face as seen from the front.
  final double faceWidthMm;

  /// The shop's catalogue moulding this is (a `mouldings` document id), or
  /// null for a custom frame. Used to price orders and route them to the shop.
  final String? catalogId;

  /// A changed moulding is no longer the catalogue product, so the copy drops
  /// [catalogId].
  Moulding copyWith({FrameProfile? profile, double? faceWidthMm}) {
    return Moulding(
      profile: profile ?? this.profile,
      faceWidthMm: faceWidthMm ?? this.faceWidthMm,
    );
  }
}
