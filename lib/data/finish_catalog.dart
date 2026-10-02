import 'dart:ui';

// Finishes offered in the editor's material tray.
// TODO(realism): the Poly Haven URLs below are preview renders, not tileable
// diffuse maps, and the floor assets show plank seams. Replace with bundled
// veneer/metal textures.

const woodTextureIds = [
  'wood_cabinet_worn_long', 'wood_floor_deck', 'plywood',
  'dark_wood', 'laminate_floor', 'wood_table_001', 'coated_pine',
  'oak_wood_planks', 'teak_veneer', 'white_maple_veneer',
  'flamed_black_veneer', 'black_oak_veneer', 'walnut_veneer', 'cherry_veneer',
];

String polyHavenTextureUrl(String assetId) =>
    'https://cdn.polyhaven.com/asset_img/primary/$assetId.png?height=760';

String polyHavenThumbnailUrl(String assetId) =>
    'https://cdn.polyhaven.com/asset_img/thumbs/$assetId.png?width=200';

const metalTextureUrls = [
  // Gold leaf
  'https://images.pexels.com/photos/30243820/pexels-christina-peko-318814967-30243820.jpg?auto=compress&cs=tinysrgb&w=1200',
  // Golden paint
  'https://images.pexels.com/photos/14331332/pexels-naturezarelaxante-14331332.jpg?auto=compress&cs=tinysrgb&w=1200',
  // Silver brush strokes
  'https://images.pexels.com/photos/5202288/pexels-photo-5202288.jpeg?auto=compress&cs=tinysrgb&w=1200',
];

const paintColors = [
  Color(0xFF4E342E), // dark brown
  Color(0xFF8D6E63), // light brown
  Color(0xFF000000), // black
  Color(0xFFFFFFFF), // white
  Color(0xFF263238), // charcoal blue-grey
  Color(0xFFB71C1C), // oxblood
];
