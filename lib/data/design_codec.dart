import 'dart:ui';

import '../models/frame_design.dart';
import '../models/frame_finish.dart';
import '../models/frame_profile.dart';
import '../models/mat_spec.dart';
import '../models/moulding.dart';
import 'finish_catalog.dart';

// Converts a FrameDesign to and from plain maps (JSON-compatible: strings,
// numbers, lists, maps), which is what Firestore documents and local files
// store. Catalogue finishes are stored by id, so renaming or re-shooting a
// texture doesn't break saved drafts.

Map<String, Object?> encodeDesign(FrameDesign design) => {
      'artworkMm': {'width': design.artworkMm.width, 'height': design.artworkMm.height},
      'moulding': {
        'profile': design.moulding.profile.name,
        'faceWidthMm': design.moulding.faceWidthMm,
      },
      'mat': _encodeMat(design.mat),
      'finish': _encodeFinish(design.finish),
    };

/// Throws [FormatException] if [json] isn't a design written by [encodeDesign].
FrameDesign decodeDesign(Map<String, Object?> json) {
  try {
    final artwork = json['artworkMm'] as Map;
    final moulding = json['moulding'] as Map;
    return FrameDesign(
      artworkMm: Size(_num(artwork['width']), _num(artwork['height'])),
      moulding: Moulding(
        profile: FrameProfile.values.byName(moulding['profile'] as String),
        faceWidthMm: _num(moulding['faceWidthMm']),
      ),
      mat: _decodeMat(json['mat'] as Map),
      finish: _decodeFinish(json['finish'] as Map),
    );
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('Not a saved frame design: $e');
  }
}

Map<String, Object?> _encodeMat(MatSpec mat) => {
      'topMm': mat.topMm,
      'bottomMm': mat.bottomMm,
      'leftMm': mat.leftMm,
      'rightMm': mat.rightMm,
      'color': mat.color.toARGB32(),
      'coreColor': mat.coreColor.toARGB32(),
      'style': mat.style.name,
      'innerColor': mat.innerColor.toARGB32(),
      'revealMm': mat.revealMm,
    };

MatSpec _decodeMat(Map json) => MatSpec(
      topMm: _num(json['topMm']),
      bottomMm: _num(json['bottomMm']),
      leftMm: _num(json['leftMm']),
      rightMm: _num(json['rightMm']),
      color: Color(json['color'] as int),
      coreColor: Color(json['coreColor'] as int),
      style: MountStyle.values.byName(json['style'] as String),
      innerColor: Color(json['innerColor'] as int),
      revealMm: _num(json['revealMm']),
    );

Map<String, Object?> _encodeFinish(FrameFinish finish) => switch (finish) {
      ColorFinish(:final color) => {'kind': 'paint', 'color': color.toARGB32()},
      WoodFinish(:final id) => {'kind': 'wood', 'id': id},
      MetalFinish(:final id) => {'kind': 'metal', 'id': id},
      PhotoMouldingFinish(:final id) => {'kind': 'ornate', 'id': id},
    };

FrameFinish _decodeFinish(Map json) {
  final kind = json['kind'] as String;
  if (kind == 'paint') return ColorFinish(Color(json['color'] as int));

  final id = json['id'] as String;
  final List<FrameFinish> options = switch (kind) {
    'wood' => woodFinishes,
    'metal' => metalFinishes,
    'ornate' => photoMouldings,
    _ => throw FormatException('Unknown finish kind "$kind"'),
  };
  for (final finish in options) {
    if (_idOf(finish) == id) return finish;
  }
  throw FormatException('No $kind finish with id "$id" in the catalogue');
}

String? _idOf(FrameFinish finish) => switch (finish) {
      WoodFinish(:final id) || MetalFinish(:final id) || PhotoMouldingFinish(:final id) => id,
      ColorFinish() => null,
    };

/// Firestore returns whole numbers as int, so accept any num.
double _num(Object? value) => (value as num).toDouble();
