import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../app/app_theme.dart';
import '../models/draft.dart';
import '../models/units.dart';
import '../rendering/lighting.dart';
import '../view_models/exhibit_viewmodel.dart';
import '../widgets/frame_renderer.dart';
import 'exhibit_room_screen.dart';

/// Exhibit tab: pick saved drafts, then hang them together in a room.
class ExhibitScreen extends StatefulWidget {
  const ExhibitScreen({super.key, this.initialSelection = const {}});

  /// Drafts to start picked, e.g. the one just saved in the editor.
  final Set<String> initialSelection;

  @override
  State<ExhibitScreen> createState() => _ExhibitScreenState();
}

class _ExhibitScreenState extends State<ExhibitScreen> {
  // Created on first build, where AppScope can be read.
  late final ExhibitViewModel viewModel = ExhibitViewModel(
    auth: AppScope.of(context).auth,
    drafts: AppScope.of(context).drafts,
    artworkStorage: AppScope.of(context).artworkStorage,
    initialSelection: widget.initialSelection,
  );

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final selected = viewModel.selectedDrafts;
        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            title: const Text('Exhibit'),
            backgroundColor: AppPalette.background,
            foregroundColor: AppPalette.obsidianBlack,
          ),
          body: _body(),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.obsidianBlack,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.museum_outlined),
                label: Text(selected.isEmpty ? 'Pick drafts to hang' : 'Open room (${selected.length})'),
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExhibitRoomScreen(exhibit: viewModel, drafts: selected),
                          ),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (!viewModel.userKnown || (viewModel.user != null && viewModel.drafts == null)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.user == null) {
      return const _Message(
        icon: Icons.lock_outline,
        text: 'Sign in to see your saved drafts.',
      );
    }
    if (viewModel.error != null) {
      return const _Message(
        icon: Icons.cloud_off_outlined,
        text: "Couldn't load your drafts. Check your connection and reopen this tab.",
      );
    }
    final drafts = viewModel.drafts!;
    if (drafts.isEmpty) {
      return const _Message(
        icon: Icons.collections_outlined,
        text: 'No saved drafts yet. Frame an artwork with the + button and save it.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: drafts.length,
      itemBuilder: (context, i) => _DraftCard(viewModel: viewModel, draft: drafts[i]),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.viewModel, required this.draft});

  final ExhibitViewModel viewModel;
  final Draft draft;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.isSelected(draft.id);
    final piece = viewModel.pieceFor(draft);
    return Semantics(
      selected: selected,
      button: true,
      label: draft.title,
      child: InkWell(
        onTap: () => viewModel.toggle(draft.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppPalette.obsidianBlack : AppPalette.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FrameRenderer(
                        design: draft.design,
                        light: const Light(),
                        finishImages: piece.finishImages,
                        shaderResources: viewModel.shaderResources,
                        artworkImage: piece.artwork,
                        wallColor: AppPalette.surfaceLight,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? AppPalette.obsidianBlack : AppPalette.borderMedium,
                      ),
                    ),
                    if (viewModel.artworkFailed(draft.id))
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("Image didn't load · Retry"),
                          onPressed: () => viewModel.retryArtwork(draft),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                draft.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppPalette.obsidianBlack),
              ),
              Text(
                formatSize(draft.design.outerMm),
                style: const TextStyle(fontSize: 12, color: AppPalette.mutedZinc),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppPalette.mutedZinc),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.coolSlate)),
          ],
        ),
      ),
    );
  }
}
