import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';
import '../../models/vendor.dart';
import '../../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../../widgets/orders/order_sample_data.dart';
import '../catalog/catalog_screen.dart';
import '../editor_screen.dart';
import '../exhibit_screen.dart';
import 'new_order_screen.dart';
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

  late final _deps = AppScope.of(context);
  late final Stream<UserProfile?> _user = _deps.auth.watchUser();
  late final Stream<List<Vendor>> _vendors = _deps.vendors.watchVendors();
  Stream<List<FramingOrder>>? _orders;
  String? _ordersKey;

  /// Frame shops see the orders sent to them; everyone else their own.
  Stream<List<FramingOrder>> _ordersFor(UserProfile user) {
    final vendorId = user.vendorId;
    final key = vendorId == null ? 'customer:${user.uid}' : 'vendor:$vendorId';
    if (key != _ordersKey) {
      _ordersKey = key;
      _orders = vendorId == null
          ? _deps.orders.watchCustomerOrders(user.uid)
          : _deps.orders.watchVendorOrders(vendorId);
    }
    return _orders!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _user,
      builder: (context, userSnapshot) => StreamBuilder<List<Vendor>>(
        stream: _vendors,
        builder: (context, vendorSnapshot) {
          final user = userSnapshot.data;
          return StreamBuilder<List<FramingOrder>>(
            stream: user == null ? null : _ordersFor(user),
            builder: (context, orderSnapshot) {
              final names = {for (final v in vendorSnapshot.data ?? const <Vendor>[]) v.id: v.name};
              final items = orderSnapshot.data
                  ?.map((o) => OrderExampleItem.fromOrder(o, workshopName: names[o.vendorId] ?? 'Workshop'))
                  .toList();
              return _buildScaffold(
                user: user,
                userKnown: userSnapshot.connectionState != ConnectionState.waiting,
                allOrders: items,
                failed: orderSnapshot.hasError,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScaffold({
    required UserProfile? user,
    required bool userKnown,
    required List<OrderExampleItem>? allOrders,
    required bool failed,
  }) {
    final isShop = user?.vendorId != null;
    final orders = (allOrders ?? const <OrderExampleItem>[])
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
                  Text(
                    isShop ? 'Incoming Orders' : 'My Orders',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (user != null && !isShop)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppPalette.obsidianBlack),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New order'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NewOrderScreen()),
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
              child: _emptyState(user: user, userKnown: userKnown, allOrders: allOrders, failed: failed, isShop: isShop) ??
                  ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _OrderListCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order, isShop: isShop),
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
          if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExhibitScreen()));
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

extension on _MyOrdersScreenState {
  /// A message instead of the list, or null to show the list.
  Widget? _emptyState({
    required UserProfile? user,
    required bool userKnown,
    required List<OrderExampleItem>? allOrders,
    required bool failed,
    required bool isShop,
  }) {
    String? message;
    if (!userKnown || (user != null && allOrders == null && !failed)) {
      return const Center(child: CircularProgressIndicator());
    } else if (user == null) {
      message = 'Sign in to see your orders.';
    } else if (failed) {
      message = "Couldn't load orders. Check your connection.";
    } else if (!allOrders!.any((o) => o.isPastOrder == _showPastOrders)) {
      message = _showPastOrders
          ? 'No completed orders yet.'
          : isShop
              ? 'No active orders. New orders from customers appear here.'
              : 'No active orders. Tap "New order" to send a saved draft to a workshop.';
    }
    if (message == null) return null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.coolSlate)),
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
