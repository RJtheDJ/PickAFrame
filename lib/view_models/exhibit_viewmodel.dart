import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../models/draft.dart';
import '../models/user_profile.dart';
import '../rendering/shaded_frame_painter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/draft_repository.dart';
import '../services/artwork_storage.dart';
import '../services/texture_service.dart';
import '../widgets/room_preview.dart';
import 'editor_viewmodel.dart';

/// The signed-in user's saved drafts, which ones are picked for the room, and
/// the images needed to draw them.
class ExhibitViewModel extends ChangeNotifier {
  ExhibitViewModel({
    required AuthRepository auth,
    required this._drafts,
    ArtworkStorage? artworkStorage,
    Set<String> initialSelection = const {},
    TextureService? textureService,
    bool loadShader = true,
  })  : _storage = artworkStorage,
        _textures = textureService ?? TextureService(),
        _selected = {...initialSelection} {
    _userSub = auth.watchUser().listen(_onUser);
    if (loadShader) {
      FrameShaderResources.load().then((resources) {
        if (_disposed) return;
        _shaderResources = resources;
        notifyListeners();
      });
    }
  }

  final DraftRepository _drafts;
  final ArtworkStorage? _storage;
  final TextureService _textures;
  final Set<String> _selected;

  StreamSubscription<UserProfile?>? _userSub;
  StreamSubscription<List<Draft>>? _draftSub;
  UserProfile? _user;
  bool _userKnown = false;
  List<Draft>? _list;
  Object? _error;

  FrameShaderResources? _shaderResources;
  final _finishImages = <String, FinishImages>{};
  final _artworks = <String, ui.Image>{};
  final _artworkErrors = <String>{};
  // Started loads, so repeated Firestore updates don't download twice.
  final _loading = <String>{};
  bool _disposed = false;

  /// False until the sign-in state is known.
  bool get userKnown => _userKnown;
  UserProfile? get user => _user;

  /// The user's drafts, newest first; null while loading.
  List<Draft>? get drafts => _list;
  Object? get error => _error;
  FrameShaderResources? get shaderResources => _shaderResources;

  bool isSelected(String draftId) => _selected.contains(draftId);

  /// Picked drafts, in list order.
  List<Draft> get selectedDrafts => [for (final d in _list ?? const <Draft>[]) if (_selected.contains(d.id)) d];

  bool artworkFailed(String draftId) => _artworkErrors.contains(draftId);

  /// [draft] as a piece to draw, with whatever images have loaded so far.
  RoomPiece pieceFor(Draft draft) => RoomPiece(
        id: draft.id,
        design: draft.design,
        artwork: _artworks[draft.id],
        finishImages: switch (EditorViewModel.assetsOf(draft.design.finish)) {
          final assets? => _finishImages[assets.first],
          null => null,
        },
      );

  void toggle(String draftId) {
    if (!_selected.remove(draftId)) _selected.add(draftId);
    notifyListeners();
  }

  void retryArtwork(Draft draft) {
    _artworkErrors.remove(draft.id);
    notifyListeners();
    _loadArtwork(draft);
  }

  void _onUser(UserProfile? user) {
    _userKnown = true;
    if (user?.uid == _user?.uid && _draftSub != null) return;
    _user = user;
    _draftSub?.cancel();
    _draftSub = null;
    _list = user == null ? const [] : null;
    _error = null;
    notifyListeners();
    if (user == null) return;

    _draftSub = _drafts.watchDrafts(user.uid).listen(
      (drafts) {
        _list = drafts;
        _error = null;
        // Forget picks of drafts that were deleted meanwhile.
        _selected.retainAll(drafts.map((d) => d.id));
        notifyListeners();
        for (final draft in drafts) {
          _loadFinish(draft);
          _loadArtwork(draft);
        }
      },
      onError: (Object e) {
        debugPrint('Error loading drafts: $e');
        _error = e;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFinish(Draft draft) async {
    final assets = EditorViewModel.assetsOf(draft.design.finish);
    if (assets == null || !_loading.add(assets.first)) return;
    try {
      final images = await _textures.loadSet(assets);
      if (_disposed) return;
      _finishImages[assets.first] = images;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading finish ${assets.first}: $e');
      _loading.remove(assets.first); // try again on the next update
    }
  }

  Future<void> _loadArtwork(Draft draft) async {
    final storage = _storage;
    final url = draft.artworkUrl;
    // Failed loads wait for retryArtwork().
    if (storage == null || url == null || _artworkErrors.contains(draft.id)) return;
    // shortcut: an artwork re-saved while this screen is open keeps showing the
    // old image until the screen is reopened; reload on updatedAt if that matters.
    if (!_loading.add('artwork:${draft.id}')) return;
    try {
      final codec = await ui.instantiateImageCodec(await storage.loadArtwork(url));
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (_disposed) return;
      _artworks[draft.id] = image;
    } catch (e) {
      debugPrint('Error loading artwork for ${draft.id}: $e');
      _artworkErrors.add(draft.id);
      _loading.remove('artwork:${draft.id}');
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _userSub?.cancel();
    _draftSub?.cancel();
    _textures.dispose();
    super.dispose();
  }
}
