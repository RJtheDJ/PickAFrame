import '../data/design_codec.dart';
import 'frame_design.dart';

/// Where a saved design is in its life (status tag on wireframe e).
enum DraftStatus { draft, exhibit, ordered }

/// A saved artwork + frame combination in the user's Drafts & Portfolio.
class Draft {
  const Draft({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.design,
    required this.updatedAt,
    this.status = DraftStatus.draft,
    this.artworkUrl,
    this.previewUrl,
  });

  final String id;
  final String ownerUid;
  final String title;
  final FrameDesign design;
  final DraftStatus status;

  /// The cropped artwork image, once uploaded (e.g. Firebase Storage).
  final String? artworkUrl;

  /// An exported mock-up, for the draft's card.
  final String? previewUrl;

  final DateTime updatedAt;

  Draft copyWith({
    String? title,
    FrameDesign? design,
    DraftStatus? status,
    String? artworkUrl,
    String? previewUrl,
    DateTime? updatedAt,
  }) =>
      Draft(
        id: id,
        ownerUid: ownerUid,
        title: title ?? this.title,
        design: design ?? this.design,
        status: status ?? this.status,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        previewUrl: previewUrl ?? this.previewUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'title': title,
        'design': encodeDesign(design),
        'status': status.name,
        'artworkUrl': artworkUrl,
        'previewUrl': previewUrl,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory Draft.fromJson(Map<String, Object?> json) => Draft(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        title: json['title'] as String,
        design: decodeDesign((json['design'] as Map).cast<String, Object?>()),
        status: DraftStatus.values.byName(json['status'] as String),
        artworkUrl: json['artworkUrl'] as String?,
        previewUrl: json['previewUrl'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
