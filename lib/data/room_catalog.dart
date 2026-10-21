import 'dart:ui';

import '../models/frame_finish.dart';
import '../models/room_scene.dart';
import 'finish_catalog.dart';

// Scenes and wall colours offered in the in-room preview.

const roomScenes = [
  RoomScene(
    id: 'living_room',
    name: 'Living room',
    wallHeightMm: 2700,
    defaultWallColor: Color(0xFFC9CDB4), // sage
    floor: FloorKind.oak,
    lighting: RoomLighting.soft,
    skirtingMm: 110,
    crownMoulding: true,
    furniture: Furniture.sofa,
  ),
  RoomScene(
    id: 'home_wall',
    name: 'Home wall',
    wallHeightMm: 2700,
    defaultWallColor: Color(0xFFA9C6D6), // powder blue
    floor: FloorKind.maple,
    lighting: RoomLighting.soft,
    skirtingMm: 90,
    furniture: Furniture.sideboard,
  ),
  RoomScene(
    id: 'white_cube',
    name: 'White cube gallery',
    wallHeightMm: 4000,
    defaultWallColor: Color(0xFFF4F3EF),
    floor: FloorKind.concrete,
    lighting: RoomLighting.spotlight,
  ),
  RoomScene(
    id: 'skylight_gallery',
    name: 'Skylight gallery',
    wallHeightMm: 4000,
    defaultWallColor: Color(0xFFF4F3EF),
    floor: FloorKind.walnut,
    lighting: RoomLighting.skylight,
    partitionWidthMm: 5200,
    furniture: Furniture.bench,
  ),
];

const wallColors = [
  (name: 'Gallery white', color: Color(0xFFF4F3EF)),
  (name: 'Warm white', color: Color(0xFFEDE6D8)),
  (name: 'Greige', color: Color(0xFFCFC6B8)),
  (name: 'Sage', color: Color(0xFFC9CDB4)),
  (name: 'Powder blue', color: Color(0xFFA9C6D6)),
  (name: 'Blush', color: Color(0xFFE6C9C1)),
  (name: 'Terracotta', color: Color(0xFFB8674A)),
  (name: 'Forest green', color: Color(0xFF3E5446)),
  (name: 'Navy', color: Color(0xFF2B3A55)),
  (name: 'Charcoal', color: Color(0xFF3A3B3D)),
];

/// Wood texture for each wooden floor kind, reusing the frame veneers.
/// Null for floors drawn without a texture (concrete).
TextureSet? floorTextures(FloorKind floor) {
  final id = switch (floor) {
    FloorKind.oak => 'oak',
    FloorKind.maple => 'maple',
    FloorKind.walnut => 'rosewood',
    FloorKind.concrete => null,
  };
  if (id == null) return null;
  return woodFinishes.firstWhere((wood) => wood.id == id).textures;
}
