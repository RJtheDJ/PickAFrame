import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'generative_frame_painter.dart'; 
import '../view_models/editor_viewmodel.dart'; 

class FrameRenderer extends StatelessWidget {
  final double frameWidth;
  final double matWidth;
  final String? artworkPath;
  final FrameMode mode;
  final FrameProfile profile;
  final Color selectedColor;
  final ui.Image? frameTexture; 

  const FrameRenderer({
    super.key,
    required this.frameWidth,
    required this.matWidth,
    this.artworkPath,
    required this.mode,
    required this.profile,
    required this.selectedColor,
    this.frameTexture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(10, 15),
          ),
        ],
      ),
      child: CustomPaint(
        painter: GenerativeFramePainter(
          frameWidth: frameWidth,
          mode: mode,
          profile: profile,
          selectedColor: selectedColor,
          texture: frameTexture,
        ),
        child: Container(
          margin: EdgeInsets.all(frameWidth),
          padding: EdgeInsets.all(matWidth),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                spreadRadius: -1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: artworkPath != null
              ? Image.file(File(artworkPath!), fit: BoxFit.contain)
              : Image.network(
                  'https://dummyimage.com/600x400/2c3e50/ffffff.png&text=Your+Artwork+Here',
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}