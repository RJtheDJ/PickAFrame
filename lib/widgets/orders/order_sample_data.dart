import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/user_profile.dart';

/// UI-layer example data for the Orders flow (`MyOrdersScreen` -> `OrderDetailScreen`).
///
/// Kept inside `lib/widgets/orders/` so `lib/models/` remains 100% untouched.
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
  });

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

  static const List<OrderExampleItem> sampleOrders = [
    OrderExampleItem(
      orderNumber: '0001',
      artworkTitle: 'Sunrise No.3',
      itemBadge: 'Item 1/1',
      workshopName: 'Workshop A · Bangsar',
      summaryLine: '1x Walnut 35mm · 600 × 800 mm',
      priceLabel: 'RM 380.00',
      orderDateLabel: '28 Sep, 2026',
      leadTimeHeader: 'Est. 10 d lead',
      stage: OrderStage.cut,
      artworkSizeLabel: 'Artwork: 600 × 800 mm',
      outerSizeLabel: 'Outer: 764 × 964 mm',
      mouldingLabel: 'MLD-0142 (Walnut · 35 mm)',
      mountStyle: 'Double',
      marginsMm: 'T50 B80 L50 R50',
      revealDepth: '6 mm',
      bevelDepth: '4 mm',
      glazingSpec: 'Tru-Vue Museum Glass (Archival)',
      backingBoard: 'Archival core (acid-free)',
      hangingHardware: 'D-rings + wire (auto-calc)',
      quantityLabel: '1 unit',
      accentColor: Color(0xFF422618),
    ),
    OrderExampleItem(
      orderNumber: '0002',
      artworkTitle: 'KL Monorail Dusk',
      itemBadge: 'Item 1/1',
      workshopName: 'Workshop B · Cheras',
      summaryLine: '1x Black 20mm · 420 × 594 mm',
      priceLabel: 'RM 240.00',
      orderDateLabel: '02 Oct, 2026',
      leadTimeHeader: 'Est. 7 d lead',
      stage: OrderStage.assembled,
      artworkSizeLabel: 'Artwork: 420 × 594 mm',
      outerSizeLabel: 'Outer: 560 × 734 mm',
      mouldingLabel: 'Black · 20 mm',
      mountStyle: 'Flat',
      marginsMm: 'T50 B50 L50 R50',
      revealDepth: '0 mm',
      bevelDepth: '2 mm',
      glazingSpec: 'UV-Filter Acrylic',
      backingBoard: 'Archival core (acid-free)',
      hangingHardware: 'Sawtooth + wire',
      quantityLabel: '1 unit',
      accentColor: Color(0xFF141619),
    ),
    OrderExampleItem(
      orderNumber: '0003',
      artworkTitle: 'Botanical Study IV',
      itemBadge: 'Item 1/1',
      workshopName: 'Workshop A · Bangsar',
      summaryLine: '1x Oak 25mm · 297 × 420 mm',
      priceLabel: 'RM 295.00',
      orderDateLabel: '15 Aug, 2026',
      leadTimeHeader: 'Completed',
      stage: OrderStage.completed,
      artworkSizeLabel: 'Artwork: 297 × 420 mm',
      outerSizeLabel: 'Outer: 447 × 570 mm',
      mouldingLabel: 'Oak · 25 mm',
      mountStyle: 'Flat',
      marginsMm: 'T50 B50 L50 R50',
      revealDepth: '0 mm',
      bevelDepth: '2 mm',
      glazingSpec: 'Standard Clear Glass',
      backingBoard: 'Archival core (acid-free)',
      hangingHardware: 'D-rings + wire (auto-calc)',
      quantityLabel: '1 unit',
      accentColor: Color(0xFFC59B6D),
      isPastOrder: true,
    ),
  ];
}
