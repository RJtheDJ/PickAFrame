import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditorViewModel extends ChangeNotifier {
  // Encapsulated state variables
  XFile? _artworkImage;
  double _frameWidth = 40.0;
  double _matWidth = 60.0;

  // Getters for the View to consume safely
  XFile? get artworkImage => _artworkImage;
  double get frameWidth => _frameWidth;
  double get matWidth => _matWidth;

  final ImagePicker _picker = ImagePicker();

  // Core Function 1: Upload Image
  Future<void> pickArtwork() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _artworkImage = pickedFile;
        notifyListeners(); // Notifies the View to rebuild with the new image
      }
    } catch (e) {
      // Handle platform exceptions gracefully
      debugPrint("Error picking image: $e");
    }
  }

  // Core Function 4: Adjust Properties
  void updateFrameWidth(double width) {
    if (_frameWidth != width) {
      _frameWidth = width;
      notifyListeners();
    }
  }

  void updateMatWidth(double width) {
    if (_matWidth != width) {
      _matWidth = width;
      notifyListeners();
    }
  }
}