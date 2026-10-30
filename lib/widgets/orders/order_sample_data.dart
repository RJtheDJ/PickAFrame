import 'package:flutter/material.dart';

import '../../data/finish_catalog.dart';
import '../../models/mat_spec.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';

/// What the Orders screens show for one order (`MyOrdersScreen` ->
/// `OrderDetailScreen`), built from a live [FramingOrder] by [fromOrder].
class OrderExampleItem {
  const OrderExampleItem({
    required this.orderNumber,
    required this.artworkTitle,
    required this.itemBadge,
    required this.workshopName,
    required this.summaryLine,
    required this.priceLabel,
    required this.orderDateLabel,
    required this.leadTimeHeader,
    required this.stage,
    required this.artworkSizeLabel,
    required this.outerSizeLabel,
    required this.mouldingLabel,
    required this.mountStyle,
    required this.marginsMm,
    required this.revealDepth,
    required this.bevelDepth,
    required this.glazingSpec,
    required this.backingBoard,
    required this.hangingHardware,
    required this.quantityLabel,
    required this.accentColor,
    this.isPastOrder = false,
    this.source,
  });

  factory OrderExampleItem.fromOrder(FramingOrder order, {required String workshopName}) {
    final design = order.design;
    final spec = {for (final (label, value) in order.specLines) label: value};
    final mat = design?.mat;
    String mm(double value) => '${value.round()}';
    final price = order.priceRm;
    final date = order.createdAt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final id = order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id;

    return OrderExampleItem(
      orderNumber: id.toUpperCase(),
      artworkTitle: order.title,
      itemBadge: 'Item 1/1',
      workshopName: workshopName,
      summaryLine: '1x ${spec['Frame'] ?? 'Custom frame'} · ${spec['Artwork'] ?? ''}',
      priceLabel: price == null
          ? 'Awaiting quote'
          : 'RM ${price.toStringAsFixed(2)}${order.quoteRm == null ? ' (estimate)' : ''}',
      orderDateLabel: '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}',
      leadTimeHeader: order.stage == OrderStage.completed ? 'Completed' : 'Now: ${order.stage.label}',
      stage: order.stage,
      artworkSizeLabel: 'Artwork: ${spec['Artwork'] ?? '—'}',
      outerSizeLabel: 'Outer: ${spec['Overall'] ?? '—'}',
      mouldingLabel: spec['Frame'] ?? '—',
      mountStyle: mat?.style.label ?? '—',
      marginsMm: mat == null
          ? (spec['Mat'] ?? '—')
          : 'T${mm(mat.topMm)} B${mm(mat.bottomMm)} L${mm(mat.leftMm)} R${mm(mat.rightMm)}',
      revealDepth: mat?.style == MountStyle.doubleMat ? '${mm(mat!.revealMm)} mm' : '0 mm',
      bevelDepth: '${mm(MatSpec.bevelMm)} mm',
      glazingSpec: 'To confirm with workshop',
      backingBoard: 'To confirm with workshop',
      hangingHardware: 'To confirm with workshop',
      quantityLabel: '1 unit',
      accentColor: design == null ? const Color(0xFF71717A) : finishSwatchColor(design.finish),
      isPastOrder: order.stage == OrderStage.completed,
      source: order,
    );
  }

  /// Numeric suffix (e.g. `'0001'`, `'0002'`, `'0003'`).
  final String orderNumber;
  final String artworkTitle;
  final String itemBadge;
  final String workshopName;
  final String summaryLine;
  final String priceLabel;
  final String orderDateLabel;
  final String leadTimeHeader;
  final OrderStage stage;
  final String artworkSizeLabel;
  final String outerSizeLabel;
  final String mouldingLabel;
  final String mountStyle;
  final String marginsMm;
  final String revealDepth;
  final String bevelDepth;
  final String glazingSpec;
  final String backingBoard;
  final String hangingHardware;
  final String quantityLabel;
  final Color accentColor;
  final bool isPastOrder;

  /// The live order this card shows.
  final FramingOrder? source;

  /// Temporary unified Order ID format (`#OD-0001`).
  String get orderId => '#OD-$orderNumber';

  /// Role-based Order ID helper ready for when role-specific prefixes are enabled:
  /// - Gallery Owner -> `#GO-0001`
  /// - Artist -> `#A-0001`
  /// - Frame Shop Owner -> `#FS-0001`
  /// - Default / Unauthenticated -> `#OD-0001`
  String orderIdForRole(UserRole? role) {
    final prefix = switch (role) {
      UserRole.galleryOwner => 'GO',
      UserRole.artist => 'A',
      UserRole.frameShopOwner => 'FS',
      null => 'OD',
    };
    return '#$prefix-$orderNumber';
  }
}
