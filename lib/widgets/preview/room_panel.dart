import 'package:flutter/material.dart';

import '../../data/room_catalog.dart';
import '../../rendering/room_viewport.dart';
import '../../view_models/editor_viewmodel.dart';
import '../../view_models/room_preview_viewmodel.dart';
import '../editor/color_swatch_row.dart';
import '../editor/labeled_slider.dart';

/// In-room preview controls: room, wall colour, furniture, zoom and light.
class RoomPanel extends StatelessWidget {
  const RoomPanel({super.key, required this.room, required this.editor});

  final RoomPreviewViewModel room;

  /// For the light, which is shared with the editor.
  final EditorViewModel editor;

  @override
  Widget build(BuildContext context) {
    final furniture = room.scene.furniture;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final scene in roomScenes)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(scene.name),
                    avatar: Icon(
                      scene.isGallery ? Icons.museum_outlined : Icons.chair_outlined,
                      size: 18,
                    ),
                    selected: scene == room.scene,
                    showCheckmark: false,
                    onSelected: (_) => room.selectScene(scene),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ColorSwatchRow(
          label: 'Wall',
          colors: [for (final wall in wallColors) wall.color],
          selected: room.wallColor,
          onSelected: room.setWallColor,
        ),
        if (furniture != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Show ${furniture.label.toLowerCase()} for scale'),
            value: room.showFurniture,
            onChanged: room.setShowFurniture,
          ),
        LabeledSlider(
          label: 'Zoom',
          value: room.zoom,
          min: RoomViewport.minZoom,
          max: RoomViewport.maxZoom,
          format: (zoom) => '${zoom.toStringAsFixed(1)}×',
          onChanged: room.setZoom,
        ),
        LabeledSlider(
          label: 'Light',
          value: editor.light.azimuthDeg,
          min: -180,
          max: 180,
          format: (deg) => '${deg.round()}°',
          activeColor: Colors.amber[300],
          onChanged: editor.setLightAzimuth,
        ),
        if (room.isDragged)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.vertical_align_center, size: 18),
              label: const Text('Reset position'),
              onPressed: room.resetPosition,
            ),
          ),
      ],
    );
  }
}
