import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:typed_data';

enum FrameMode { color, texture }
enum FrameProfile { flat, slope, scoop, beveled, curve, stepped, reverseSlope, triangular }

Future<ui.Image> createShaderMaterial(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

class EditorViewModel extends ChangeNotifier {
  XFile? _artworkImage;
  double _frameWidth = 40.0;
  double _matWidth = 60.0;
  
  FrameMode _currentMode = FrameMode.texture;
  FrameProfile _currentProfile = FrameProfile.beveled;
  Color _selectedColor = Colors.brown[800]!;
  ui.Image? _frameTexture;
  bool _isProcessing = false;
  
  final List<String> _curatedTextures = [
    'wood_cabinet_worn_long', 'wood_floor_deck', 'plywood', 
    'dark_wood', 'laminate_floor', 'wood_table_001', 'coated_pine', 
    'oak_wood_planks', 'teak_veneer', 'white_maple_veneer', 
    'flamed_black_veneer', 'black_oak_veneer', 'walnut_veneer', 'cherry_veneer'
  ];

  final List<String> _metalTextures = [
    'https://images.pexels.com/photos/30243820/pexels-christina-peko-318814967-30243820.jpg?auto=compress&cs=tinysrgb&w=1200', 
    'https://images.pexels.com/photos/14331332/pexels-naturezarelaxante-14331332.jpg?auto=compress&cs=tinysrgb&w=1200', 
    'https://images.pexels.com/photos/5202288/pexels-photo-5202288.jpeg?auto=compress&cs=tinysrgb&w=1200', // Silver brush strokes
  ];

  final List<Color> _colorPalette = [
    Colors.brown[800]!, Colors.brown[400]!, Colors.black, 
    Colors.white, Colors.blueGrey[900]!, Colors.red[900]!
  ];

  EditorViewModel() { _loadInitialTexture(); }

  XFile? get artworkImage => _artworkImage;
  double get frameWidth => _frameWidth;
  double get matWidth => _matWidth;
  FrameMode get currentMode => _currentMode;
  FrameProfile get currentProfile => _currentProfile;
  Color get selectedColor => _selectedColor;
  ui.Image? get frameTexture => _frameTexture;
  bool get isProcessing => _isProcessing;
  List<String> get curatedTextures => _curatedTextures;
  List<String> get metalTextures => _metalTextures;
  List<Color> get colorPalette => _colorPalette;

  void setMode(FrameMode mode) { _currentMode = mode; notifyListeners(); }
  void setProfile(FrameProfile profile) { _currentProfile = profile; notifyListeners(); }
  void setColor(Color color) { _selectedColor = color; notifyListeners(); }

  Future<void> _loadInitialTexture() async {
    await applyPolyHavenTexture(_curatedTextures[0]);
  }

  // Universal URL loader for Pexels and other CDNs
  Future<void> applyTextureFromUrl(String url) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _frameTexture = await createShaderMaterial(response.bodyBytes);
      }
    } catch (e) {
      debugPrint("Error loading texture: $e");
    }
    _isProcessing = false;
    notifyListeners();
  }

  // Updated to reuse the universal loader
  Future<void> applyPolyHavenTexture(String assetId) async {
    final url = 'https://cdn.polyhaven.com/asset_img/primary/$assetId.png?height=760';
    await applyTextureFromUrl(url);
  }

  Future<void> pickArtwork() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _artworkImage = pickedFile;
      notifyListeners();
    }
  }

  void updateFrameWidth(double w) { _frameWidth = w; notifyListeners(); }
  void updateMatWidth(double w) { _matWidth = w; notifyListeners(); }
}