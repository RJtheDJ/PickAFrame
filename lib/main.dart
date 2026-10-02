import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; // Fluent UI Icons
import 'view_models/editor_viewmodel.dart';
import 'widgets/frame_renderer.dart';

void main() {
  runApp(const FramingApp());
}

class FramingApp extends StatelessWidget { 
  const FramingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      debugShowCheckedModeBanner: false, 
      title: 'Frame Simulator', 
      home: const FrameViewerScreen(), 
    );
  }
}

class FrameViewerScreen extends StatefulWidget { 
  const FrameViewerScreen({super.key});

  @override
  State<FrameViewerScreen> createState() => _FrameViewerScreenState(); 
}

class _FrameViewerScreenState extends State<FrameViewerScreen> {
  final EditorViewModel viewModel = EditorViewModel();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.blueGrey[900],
          appBar: AppBar(
            title: const Text('Basic Framing Engine'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: () => viewModel.pickArtwork(), // Keeps artwork picker intact
                tooltip: 'Upload Artwork',
              ),
            ],
          ),
          body: Column(
            children: [
              // FRAME RENDERER
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: viewModel.isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : FrameRenderer(
                            frameWidth: viewModel.frameWidth,
                            matWidth: viewModel.matWidth,
                            artworkPath: viewModel.artworkImage?.path,
                            mode: viewModel.currentMode,
                            profile: viewModel.currentProfile,
                            selectedColor: viewModel.selectedColor,
                            frameTexture: viewModel.frameTexture,
                          ),
                  ),
                ),
              ),
              // CONTROL PANEL
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Profile Bevels & Mode Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: FrameProfile.values.map((profile) {
                                  final isSelected = viewModel.currentProfile == profile;
                                  final label = profile.name[0].toUpperCase() + profile.name.substring(1);
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(label),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) viewModel.setProfile(profile);
                                      },
                                      backgroundColor: Colors.black,
                                      selectedColor: Colors.blueAccent,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Colors.transparent),
                                      ),
                                      showCheckmark: false,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              viewModel.currentMode == FrameMode.texture 
                                ? FluentIcons.paint_brush_24_regular 
                                : FluentIcons.image_24_regular
                            ),
                            color: Colors.white,
                            tooltip: 'Toggle Color/Texture',
                            onPressed: () => viewModel.setMode(
                              viewModel.currentMode == FrameMode.texture 
                                ? FrameMode.color 
                                : FrameMode.texture
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Width Sliders
                      Row(
                        children: [
                          const Text('Frame', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: viewModel.frameWidth,
                              min: 10.0,
                              max: 120.0,
                              activeColor: Colors.brown[400],
                              onChanged: (newValue) => viewModel.updateFrameWidth(newValue),
                            ),
                          ),
                          Text('${viewModel.frameWidth.toInt()} px', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Mat    ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: viewModel.matWidth,
                              min: 0.0,
                              max: 120.0,
                              activeColor: const Color(0xFFF5F5F0),
                              onChanged: (newValue) => viewModel.updateMatWidth(newValue),
                            ),
                          ),
                          Text('${viewModel.matWidth.toInt()} px', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      
                      // Dynamic Palette Generator
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: viewModel.currentMode == FrameMode.color
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: viewModel.colorPalette.length,
                                itemBuilder: (context, index) {
                                  final color = viewModel.colorPalette[index];
                                  return GestureDetector(
                                    onTap: () => viewModel.setColor(color),
                                    child: Container(
                                      width: 60,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: color, 
                                        shape: BoxShape.circle, 
                                        border: Border.all(
                                          color: viewModel.selectedColor == color ? Colors.blueAccent : Colors.white38,
                                          width: viewModel.selectedColor == color ? 3 : 1,
                                        )
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // Map Wood Textures
                                  ...viewModel.curatedTextures.map((assetId) {
                                    return GestureDetector(
                                      onTap: () => viewModel.applyPolyHavenTexture(assetId),
                                      child: Container(
                                        width: 60,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white38, width: 1),
                                          image: DecorationImage(
                                            image: NetworkImage('https://cdn.polyhaven.com/asset_img/thumbs/$assetId.png?width=200'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  // Map Metal Textures
                                  ...viewModel.metalTextures.map((url) {
                                    return GestureDetector(
                                      onTap: () => viewModel.applyTextureFromUrl(url),
                                      child: Container(
                                        width: 60,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.amber, width: 2), // Gold border for visibility
                                          image: DecorationImage(
                                            image: NetworkImage(url),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}