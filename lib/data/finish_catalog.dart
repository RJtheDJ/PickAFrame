import 'dart:ui';

import '../models/frame_finish.dart';

// Finishes offered in the editor's material tray. Later these will come from
// vendor catalogues.

const paintColors = [
  Color(0xFF4E342E), // dark brown
  Color(0xFF8D6E63), // light brown
  Color(0xFF1C1C1C), // black
  Color(0xFFF2F0EB), // white
  Color(0xFF263238), // charcoal blue-grey
  Color(0xFF7B1F1F), // oxblood
];

// CC0 veneer textures from Poly Haven (polyhaven.com).
const woodFinishes = [
  WoodFinish(id: 'cherry', name: 'Cherry', textures: TextureSet('assets/textures/wood/cherry_veneer', sizeMm: 1000)),
  WoodFinish(id: 'teak', name: 'Teak', textures: TextureSet('assets/textures/wood/teak_veneer', sizeMm: 1000)),
  WoodFinish(id: 'oak', name: 'Oak', textures: TextureSet('assets/textures/wood/oak_veneer_01', sizeMm: 1830, grainVertical: true)),
  WoodFinish(id: 'white_oak', name: 'White oak', textures: TextureSet('assets/textures/wood/white_oak_veneer', sizeMm: 500, grainVertical: true)),
  WoodFinish(id: 'maple', name: 'Maple', textures: TextureSet('assets/textures/wood/white_maple_veneer', sizeMm: 1000)),
  WoodFinish(id: 'rosewood', name: 'Rosewood', textures: TextureSet('assets/textures/wood/rosewood_veneer1', sizeMm: 2430, grainVertical: true)),
  WoodFinish(id: 'black_oak', name: 'Black oak', textures: TextureSet('assets/textures/wood/black_oak_veneer', sizeMm: 1000)),
  WoodFinish(id: 'ebonised', name: 'Ebonised', textures: TextureSet('assets/textures/wood/flamed_black_veneer', sizeMm: 1000)),
];

// CC0 metal materials from ambientCG (ambientcg.com).
const metalFinishes = [
  MetalFinish(
    id: 'gold_leaf',
    name: 'Gold leaf',
    color: Color(0xFFB8902F),
    textures: TextureSet('assets/textures/metal/metal048a', sizeMm: 500),
  ),
  MetalFinish(
    id: 'antique_gold',
    name: 'Antique gold',
    color: Color(0xFF8E6E35),
    textures: TextureSet('assets/textures/metal/metal048c', sizeMm: 500),
    tint: Color(0xFFC9A472),
  ),
  MetalFinish(
    id: 'champagne',
    name: 'Champagne',
    color: Color(0xFFBFA878),
    textures: TextureSet('assets/textures/metal/metal042a', sizeMm: 500),
    tint: Color(0xFFF2E8DA),
  ),
  MetalFinish(
    id: 'silver',
    name: 'Silver',
    color: Color(0xFFA9AEB4),
    textures: TextureSet('assets/textures/metal/metal049a', sizeMm: 500),
  ),
  MetalFinish(
    id: 'brushed_steel',
    name: 'Brushed steel',
    color: Color(0xFF8E9196),
    textures: TextureSet('assets/textures/metal/metal009', sizeMm: 300),
  ),
  MetalFinish(
    id: 'aluminium',
    name: 'Aluminium',
    color: Color(0xFFB4B8BC),
    textures: TextureSet('assets/textures/metal/metal050c', sizeMm: 500),
  ),
  MetalFinish(
    id: 'copper',
    name: 'Copper',
    color: Color(0xFF9A5A2C),
    textures: TextureSet('assets/textures/metal/metal035', sizeMm: 500),
  ),
  MetalFinish(
    id: 'black_metal',
    name: 'Black metal',
    color: Color(0xFF2B2B2E),
    textures: TextureSet('assets/textures/metal/metal046a', sizeMm: 500),
    tint: Color(0xFF8A8A8C),
  ),
];

// TEST ONLY: cut from a reference photo supplied during development, whose
// licence is unknown. Replace with photos of real vendor mouldings before
// release (see tools/make_moulding_strip.py).
const photoMouldings = [
  PhotoMouldingFinish(
    id: 'ornate_gold_scroll',
    name: 'Ornate gold scroll',
    asset: 'assets/mouldings/ornate_gold_scroll.jpg',
    faceWidthMm: 60,
  ),
];

/// One colour standing in for [finish] in small previews (catalogue cards,
/// map pins). Wood colours are the average of each veneer texture.
Color finishSwatchColor(FrameFinish finish) => switch (finish) {
      ColorFinish(:final color) || MetalFinish(:final color) => color,
      WoodFinish(:final id) => _woodSwatches[id] ?? const Color(0xFFA17E57),
      PhotoMouldingFinish() => const Color(0xFFA8842F),
    };

const _woodSwatches = {
  'cherry': Color(0xFFE0AF83),
  'teak': Color(0xFFAF8156),
  'oak': Color(0xFFA17E57),
  'white_oak': Color(0xFF907962),
  'maple': Color(0xFFE3D4B8),
  'rosewood': Color(0xFF6D3210),
  'black_oak': Color(0xFF6B6157),
  'ebonised': Color(0xFF55504D),
};
