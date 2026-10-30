import '../data/design_codec.dart';
import 'frame_design.dart';
import 'frame_finish.dart';
import 'frame_profile.dart';
import 'moulding.dart';

/// Material classes a catalogue moulding can be filed under. Must match the
/// list in firebase/firestore.rules.
const mouldingMaterialClasses = [
  'Wood (Hardwood)',
  'Aluminium Metal',
  'Composite Polymer',
  'Gilded / Foil Leaf',
];

/// A moulding a frame shop sells (Unified Frame Catalogue, wireframe c),
/// stored in the `mouldings` collection. [profile], [finish] and
/// [faceWidthMm] are how it looks in the editor.
class CatalogMoulding {
  const CatalogMoulding({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.profile,
    required this.finish,
    required this.faceWidthMm,
    required this.rebateDepthMm,
    required this.pricePerMetreRm,
    required this.materialClass,
    required this.createdAt,
  });

  final String id;

  /// The shop selling it (vendor id = the shop owner's uid).
  final String vendorId;
  final String name;
  final FrameProfile profile;
  final FrameFinish finish;
  final double faceWidthMm;
  final double rebateDepthMm;
  final double pricePerMetreRm;

  /// One of [mouldingMaterialClasses].
  final String materialClass;
  final DateTime createdAt;

  /// This moulding on [design]'s artwork.
  FrameDesign applyTo(FrameDesign design) => design.copyWith(
        moulding: Moulding(profile: profile, faceWidthMm: faceWidthMm, catalogId: id),
        finish: finish,
      );

  /// Price of the moulding for [design], from the length needed to frame it.
  double priceFor(FrameDesign design) => pricePerMetreRm * design.mouldingLengthMm / 1000;

  CatalogMoulding copyWith({
    String? name,
    FrameProfile? profile,
    FrameFinish? finish,
    double? faceWidthMm,
    double? rebateDepthMm,
    double? pricePerMetreRm,
    String? materialClass,
  }) =>
      CatalogMoulding(
        id: id,
        vendorId: vendorId,
        name: name ?? this.name,
        profile: profile ?? this.profile,
        finish: finish ?? this.finish,
        faceWidthMm: faceWidthMm ?? this.faceWidthMm,
        rebateDepthMm: rebateDepthMm ?? this.rebateDepthMm,
        pricePerMetreRm: pricePerMetreRm ?? this.pricePerMetreRm,
        materialClass: materialClass ?? this.materialClass,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'vendorId': vendorId,
        'name': name,
        'profile': profile.name,
        'finish': encodeFinish(finish),
        'faceWidthMm': faceWidthMm,
        'rebateDepthMm': rebateDepthMm,
        'pricePerMetreRm': pricePerMetreRm,
        'materialClass': materialClass,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  /// Throws [FormatException] for documents that can't be shown.
  factory CatalogMoulding.fromJson(Map<String, Object?> json) {
    try {
      return CatalogMoulding(
        id: json['id'] as String,
        vendorId: json['vendorId'] as String,
        name: json['name'] as String,
        profile: FrameProfile.values.byName(json['profile'] as String),
        finish: decodeFinish(json['finish'] as Map),
        faceWidthMm: (json['faceWidthMm'] as num).toDouble(),
        rebateDepthMm: (json['rebateDepthMm'] as num).toDouble(),
        pricePerMetreRm: (json['pricePerMetreRm'] as num).toDouble(),
        materialClass: json['materialClass'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(2026),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Not a catalogue moulding: $e');
    }
  }
}
