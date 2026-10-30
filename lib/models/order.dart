import '../data/design_codec.dart';
import 'frame_design.dart';

/// Production milestones a framing order goes through (proposal 3.1.2 (4) and
/// wireframe h), in order.
enum OrderStage {
  submitted('Submitted'),
  cut('Cut'),
  assembled('Assembled'),
  glazed('Glazed'),
  readyForDispatch('Ready for dispatch'),
  completed('Completed');

  const OrderStage(this.label);

  final String label;

  /// The stage after this one, or null when finished.
  OrderStage? get next =>
      index + 1 < OrderStage.values.length ? OrderStage.values[index + 1] : null;
}

/// A framing job sent from a customer to a workshop.
class FramingOrder {
  const FramingOrder({
    required this.id,
    required this.draftId,
    required this.customerUid,
    required this.vendorId,
    required this.specLines,
    required this.createdAt,
    this.title = 'Untitled',
    this.design,
    this.estimateRm,
    this.stage = OrderStage.submitted,
    this.quoteRm,
  });

  final String id;
  final String draftId;
  final String customerUid;
  final String vendorId;

  /// The draft's title when the order was placed.
  final String title;

  /// The specification sheet at the time of ordering (label, value), frozen
  /// so later edits to the draft don't change what the workshop cuts.
  final List<(String, String)> specLines;

  /// The full design at the time of ordering, for the workshop's cut sizes
  /// and the order's preview. Null for orders placed before it was stored.
  final FrameDesign? design;

  /// The app's price estimate when ordered (catalogue moulding price per metre
  /// x moulding length), or null for custom frames the shop must price.
  final double? estimateRm;

  final OrderStage stage;

  /// The workshop's confirmed quote in ringgit, once given.
  final double? quoteRm;
  final DateTime createdAt;

  /// The price to show: the shop's quote, else the app's estimate.
  double? get priceRm => quoteRm ?? estimateRm;

  FramingOrder copyWith({OrderStage? stage, double? quoteRm}) => FramingOrder(
        id: id,
        draftId: draftId,
        customerUid: customerUid,
        vendorId: vendorId,
        specLines: specLines,
        createdAt: createdAt,
        title: title,
        design: design,
        estimateRm: estimateRm,
        stage: stage ?? this.stage,
        quoteRm: quoteRm ?? this.quoteRm,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'draftId': draftId,
        'customerUid': customerUid,
        'vendorId': vendorId,
        'title': title,
        'specLines': [
          for (final (label, value) in specLines) {'label': label, 'value': value},
        ],
        'design': design == null ? null : encodeDesign(design!),
        'estimateRm': estimateRm,
        'stage': stage.name,
        'quoteRm': quoteRm,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory FramingOrder.fromJson(Map<String, Object?> json) => FramingOrder(
        id: json['id'] as String,
        draftId: json['draftId'] as String,
        customerUid: json['customerUid'] as String,
        vendorId: json['vendorId'] as String,
        title: json['title'] as String? ?? 'Untitled',
        specLines: [
          for (final line in (json['specLines'] as List).cast<Map>())
            (line['label'] as String, line['value'] as String),
        ],
        design: switch (json['design']) {
          final Map<Object?, Object?> design => decodeDesign(design.cast()),
          _ => null,
        },
        estimateRm: (json['estimateRm'] as num?)?.toDouble(),
        stage: OrderStage.values.byName(json['stage'] as String),
        quoteRm: (json['quoteRm'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
