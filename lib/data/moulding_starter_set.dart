import 'dart:ui';

import '../models/catalog_moulding.dart';
import '../models/frame_finish.dart';
import '../models/frame_profile.dart';
import 'finish_catalog.dart';

/// Six typical mouldings a shop can add in one tap, so its catalogue isn't
/// empty on day one. Fixed ids per shop: adding again updates, never
/// duplicates. Prices are placeholders the shop should edit.
List<CatalogMoulding> starterMouldings(String vendorId) {
  FrameFinish wood(String id) => woodFinishes.firstWhere((w) => w.id == id);
  FrameFinish metal(String id) => metalFinishes.firstWhere((m) => m.id == id);
  final now = DateTime.now();

  CatalogMoulding m(
    String key,
    String name,
    FrameProfile profile,
    FrameFinish finish,
    double width,
    double rebate,
    double price,
    String material,
  ) =>
      CatalogMoulding(
        id: '${vendorId}_starter_$key',
        vendorId: vendorId,
        name: name,
        profile: profile,
        finish: finish,
        faceWidthMm: width,
        rebateDepthMm: rebate,
        pricePerMetreRm: price,
        materialClass: material,
        createdAt: now,
      );

  return [
    m('cherry', 'Cherry Classic 35mm', FrameProfile.beveled, wood('cherry'), 35, 14, 38, 'Wood (Hardwood)'),
    m('oak', 'Natural Oak 25mm', FrameProfile.flat, wood('oak'), 25, 12, 31, 'Wood (Hardwood)'),
    m('black', 'Matte Black 20mm', FrameProfile.flat, metal('black_metal'), 20, 11, 24, 'Aluminium Metal'),
    m('gilded', 'Gilded Scoop 50mm', FrameProfile.scoop, metal('gold_leaf'), 50, 25, 96, 'Gilded / Foil Leaf'),
    m('ornate', 'Ornate Gold Scroll 60mm', FrameProfile.flat, photoMouldings.first, 60, 25, 145, 'Gilded / Foil Leaf'),
    m('white', 'Gallery White 30mm', FrameProfile.slope, const ColorFinish(Color(0xFFF2F0EB)), 30, 15, 28,
        'Composite Polymer'),
  ];
}
