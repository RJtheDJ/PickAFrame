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
    this.stage = OrderStage.submitted,
    this.quoteRm,
  });

  final String id;
  final String draftId;
  final String customerUid;
  final String vendorId;

  /// The specification sheet at the time of ordering (label, value), frozen
  /// so later edits to the draft don't change what the workshop cuts.
  final List<(String, String)> specLines;

  final OrderStage stage;

  /// The workshop's quote in ringgit, once given.
  final double? quoteRm;
  final DateTime createdAt;

  FramingOrder copyWith({OrderStage? stage, double? quoteRm}) => FramingOrder(
        id: id,
        draftId: draftId,
        customerUid: customerUid,
        vendorId: vendorId,
        specLines: specLines,
        createdAt: createdAt,
        stage: stage ?? this.stage,
        quoteRm: quoteRm ?? this.quoteRm,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'draftId': draftId,
        'customerUid': customerUid,
        'vendorId': vendorId,
        'specLines': [
          for (final (label, value) in specLines) {'label': label, 'value': value},
        ],
        'stage': stage.name,
        'quoteRm': quoteRm,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory FramingOrder.fromJson(Map<String, Object?> json) => FramingOrder(
        id: json['id'] as String,
        draftId: json['draftId'] as String,
        customerUid: json['customerUid'] as String,
        vendorId: json['vendorId'] as String,
        specLines: [
          for (final line in (json['specLines'] as List).cast<Map>())
            (line['label'] as String, line['value'] as String),
        ],
        stage: OrderStage.values.byName(json['stage'] as String),
        quoteRm: (json['quoteRm'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
