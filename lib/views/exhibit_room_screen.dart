import 'package:flutter/material.dart';

import '../models/draft.dart';
import '../models/units.dart';
import '../view_models/exhibit_viewmodel.dart';
import '../view_models/room_preview_viewmodel.dart';
import '../widgets/export_button.dart';
import '../widgets/preview/room_panel.dart';
import '../widgets/room_preview.dart';
import '../widgets/workspace_layout.dart';

/// The picked drafts hung together in a room. Leaving never changes or
/// deletes the drafts.
class ExhibitRoomScreen extends StatefulWidget {
  const ExhibitRoomScreen({super.key, required this.exhibit, required this.drafts});

  /// Supplies each draft's images as they load.
  final ExhibitViewModel exhibit;
  final List<Draft> drafts;

  @override
  State<ExhibitRoomScreen> createState() => _ExhibitRoomScreenState();
}

class _ExhibitRoomScreenState extends State<ExhibitRoomScreen> {
  final room = RoomPreviewViewModel();
  final _exportKey = GlobalKey();

  @override
  void dispose() {
    room.dispose();
    super.dispose();
  }

  String _shareMessage() => [
    'Framed with PickAFrame',
    for (final draft in widget.drafts) '${draft.title}: ${formatSize(draft.design.outerMm)}',
    'Shown in: ${room.scene.name}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([room, widget.exhibit]),
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          title: const Text('Exhibit room'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [ExportButton(boundaryKey: _exportKey, message: _shareMessage)],
        ),
        body: WorkspaceLayout(
          controlsHeight: 300,
          preview: RoomPreview(
            room: room,
            pieces: [for (final draft in widget.drafts) widget.exhibit.pieceFor(draft)],
            shaderResources: widget.exhibit.shaderResources,
            exportKey: _exportKey,
          ),
          controls: Theme(
            data: ThemeData(brightness: Brightness.light, useMaterial3: true),
            // Material, so list tiles' ink shows on the dark panel.
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafeArea(top: false, child: RoomPanel(room: room)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
