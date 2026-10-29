import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../../widgets/orders/order_sample_data.dart';
import '../catalog/catalog_screen.dart';
import '../editor_screen.dart';
import 'order_detail_screen.dart';

/// Order list screen (`My Orders` — Image 3 structure) shown when the user taps
/// `Orders` on the bottom navigation bar.
///
/// Features:
/// - `Active Orders` and `Past Orders` tabs
/// - Clickable example order cards with framed artwork thumbnail, workshop name,
///   item summary, price, and `View order details` + `Order date` footer
/// - Tapping any order card navigates to [OrderDetailScreen] (Image 1).
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _showPastOrders = false;

  @override
  Widget build(BuildContext context) {
    final orders = OrderExampleItem.sampleOrders
        .where((o) => o.isPastOrder == _showPastOrders)
        .toList();

    return Scaffold(
      backgroundColor: AppPalette.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar: <- My Orders
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppPalette.background,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppPalette.obsidianBlack,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Two-Tab Bar: Active Orders | Past Orders (matching Image 3)
            Container(
              decoration: const BoxDecoration(
                color: AppPalette.background,
                border: Border(
                  bottom: BorderSide(color: AppPalette.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _OrderTabButton(
                      label: 'Active Orders',
                      selected: !_showPastOrders,
                      onTap: () => setState(() => _showPastOrders = false),
                    ),
                  ),
                  Expanded(
                    child: _OrderTabButton(
                      label: 'Past Orders',
                      selected: _showPastOrders,
                      onTap: () => setState(() => _showPastOrders = true),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Clickable Order Cards List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _OrderListCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CatalogBottomNavBar(
        currentIndex: 3, // Orders tab highlighted
        onTabSelected: (index) {
          if (index == 3) return;
          if (index == 1) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            }
            return;
          }
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        onCenterAddTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
        },
      ),
    );
  }
}

class _OrderTabButton extends StatelessWidget {
  const _OrderTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppPalette.obsidianBlack : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppPalette.obsidianBlack : AppPalette.coolSlate,
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Individual clickable order card styled after Image 3.
class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    required this.order,
    required this.onTap,
  });

  final OrderExampleItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppPalette.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppPalette.obsidianBlack.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top section: Thumbnail + Workshop/Artwork title + Summary + Price
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Framed Artwork Thumbnail
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppPalette.slateTintSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPalette.borderLight),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          border: Border.all(color: order.accentColor, width: 5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'ART',
                          style: AppTheme.monoStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.coolSlate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Right details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${order.artworkTitle} (${order.orderId})',
                                  style: const TextStyle(
                                    color: AppPalette.obsidianBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.slateTintSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.stage.label,
                                  style: AppTheme.monoStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.midnightSlate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.workshopName,
                            style: const TextStyle(
                              color: AppPalette.darkCharcoal,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.summaryLine,
                            style: const TextStyle(
                              color: AppPalette.coolSlate,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.priceLabel,
                            style: AppTheme.monoStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.midnightSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8, color: AppPalette.borderLight),

              // Bottom section: View order details + Order date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View order details',
                          style: TextStyle(
                            color: AppPalette.obsidianBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order date: ${order.orderDateLabel}',
                          style: const TextStyle(
                            color: AppPalette.mutedZinc,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppPalette.coolSlate,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
