import 'package:flutter/material.dart';

import '../services/export_service.dart';

/// App-bar button that renders [boundaryKey]'s [RepaintBoundary] at high
/// resolution, then saves it to the gallery or shares it with [message].
class ExportButton extends StatefulWidget {
  const ExportButton({super.key, required this.boundaryKey, required this.message});

  final GlobalKey boundaryKey;

  /// Text shared alongside the image, built when the user exports.
  final String Function() message;

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

enum _ExportAction { save, share }

class _ExportButtonState extends State<ExportButton> {
  bool _exporting = false;

  Future<void> _export() async {
    final box = context.findRenderObject()! as RenderBox;
    final shareOrigin = box.localToGlobal(Offset.zero) & box.size;

    final action = await showModalBottomSheet<_ExportAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSaveToGallery)
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Save to gallery'),
                onTap: () => Navigator.pop(context, _ExportAction.save),
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              subtitle: const Text('Includes the frame and mat details'),
              onTap: () => Navigator.pop(context, _ExportAction.share),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final png = await renderPng(widget.boundaryKey);
      switch (action) {
        case _ExportAction.save:
          await saveToGallery(png);
          messenger.showSnackBar(const SnackBar(content: Text('Saved to your gallery')));
        case _ExportAction.share:
          await sharePng(png, message: widget.message(), origin: shareOrigin);
      }
    } on GalleryPermissionDenied {
      messenger.showSnackBar(
        const SnackBar(content: Text('Allow access to Photos in Settings to save mock-ups')),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Export failed. Please try again.')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _exporting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.ios_share),
      tooltip: 'Export',
      onPressed: _exporting ? null : _export,
    );
  }
}
