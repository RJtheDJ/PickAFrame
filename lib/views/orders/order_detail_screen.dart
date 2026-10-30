import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/order.dart';
import '../../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../../widgets/orders/order_sample_data.dart';
import '../editor_screen.dart';

/// Order Specification & Production Tracker screen (`Screen h` — Image 1),
/// opened when clicking an order card in `MyOrdersScreen`.
///
/// Incorporates all requested cleanups and Active vs. Past Order rules:
/// - Order ID uses `#OD-[id]` (e.g. `#OD-0001`), with role-based helper ready
///   (`#GO-0001`, `#A-0001`, `#FS-0001`).
/// - Active Order (`!order.isPastOrder`): shows up to `Quantity` row only
///   (no `Download PDF` button, no `Route to workshop` section).
/// - Past Order (`order.isPastOrder`): shows up to `Download PDF` (100% width)
///   at the bottom of the specification card (no `Route to workshop` section).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order, this.isShop = false});

  final OrderExampleItem order;

  /// Viewed by the workshop: shows the quote and production controls.
  final bool isShop;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

/// Keeps the order live: the customer sees stage changes as the workshop
/// makes them, and the workshop sees its own updates.
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final _deps = AppScope.of(context);
  late final FramingOrder? _source = widget.order.source;
  late final Stream<List<FramingOrder>>? _orders = switch (_source) {
    null => null,
    final o => widget.isShop ? _deps.orders.watchVendorOrders(o.vendorId) : _deps.orders.watchCustomerOrders(o.customerUid),
  };
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      debugPrint('Order update failed: $e');
      messenger.showSnackBar(SnackBar(content: Text("Couldn't update the order: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setQuote(FramingOrder order) async {
    final controller = TextEditingController(text: order.priceRm?.toStringAsFixed(2) ?? '');
    final quote = await showDialog<double>(
      context: context,
      builder: (context) {
        void submit() {
          final value = double.tryParse(controller.text.trim());
          if (value != null && value >= 0 && value <= 100000) Navigator.pop(context, value);
        }

        return AlertDialog(
          title: const Text('Confirm quote'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              prefixText: 'RM ',
              helperText: order.estimateRm == null
                  ? 'Custom frame: no app estimate'
                  : 'App estimate: RM ${order.estimateRm!.toStringAsFixed(2)}',
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: submit, child: const Text('Save quote')),
          ],
        );
      },
    ).whenComplete(controller.dispose);
    if (quote != null) {
      await _run(() => _deps.orders.setQuote(order.id, quote), 'Quote set to RM ${quote.toStringAsFixed(2)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FramingOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        final live = snapshot.data?.where((o) => o.id == _source?.id).firstOrNull ?? _source;
        final item = live == null
            ? widget.order
            : OrderExampleItem.fromOrder(live, workshopName: widget.order.workshopName);
        return _OrderDetailPage(
          order: item,
          shopActions: widget.isShop && live != null ? _shopActions(live) : null,
        );
      },
    );
  }

  Widget _shopActions(FramingOrder order) {
    final next = order.stage.next;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            order.quoteRm != null
                ? 'Your quote: RM ${order.quoteRm!.toStringAsFixed(2)}'
                : order.estimateRm != null
                    ? 'App estimate: RM ${order.estimateRm!.toStringAsFixed(2)} (not confirmed)'
                    : 'Custom frame: not priced yet',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppPalette.obsidianBlack),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(order.quoteRm == null ? 'Confirm quote' : 'Change quote'),
                onPressed: _busy ? null : () => _setQuote(order),
              ),
              if (next != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppPalette.obsidianBlack),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text('Mark as ${next.label}'),
                  onPressed: _busy
                      ? null
                      : () => _run(() => _deps.orders.updateStage(order.id, next), 'Marked as ${next.label}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderDetailPage extends StatelessWidget {
  const _OrderDetailPage({required this.order, this.shopActions});

  final OrderExampleItem order;
  final Widget? shopActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Clean Top App Bar: <- Orders ... [Profile Circle]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppPalette.background,
                border: Border(
                  bottom: BorderSide(color: AppPalette.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppPalette.obsidianBlack,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Orders',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile & Role settings')),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppPalette.obsidianBlack,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Scrollable Order Spec Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Order ID Header Card (#OD-0001)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppPalette.borderLight),
                          ),
                          child: Row(
                            children: [
                              Text(
                                order.orderId,
                                style: AppTheme.monoStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.obsidianBlack,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Production Stage Target Card (Cut -> Assembled -> Glazed -> Ready)
                        _ProductionStageCard(
                          activeStage: order.stage,
                          leadTimeLabel: order.leadTimeHeader,
                        ),

                        if (shopActions != null) ...[
                          const SizedBox(height: 12),
                          shopActions!,
                        ],

                        const SizedBox(height: 12),

                        // Artwork & Specification Table Card:
                        // - Active Order: ends at Quantity
                        // - Past Order: ends at 100% width [ Download PDF ]
                        _ArtworkSpecCard(
                          order: order,
                          onDownloadPdfTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading ${order.orderId} PDF...'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CatalogBottomNavBar(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index == 3) {
            Navigator.of(context).pop();
            return;
          }
          if (index == 1) {
            Navigator.of(context)
              ..pop()
              ..pop();
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

class _ProductionStageCard extends StatelessWidget {
  const _ProductionStageCard({
    required this.activeStage,
    required this.leadTimeLabel,
  });

  final OrderStage activeStage;
  final String leadTimeLabel;

  @override
  Widget build(BuildContext context) {
    const stages = [
      (OrderStage.cut, 'Cut'),
      (OrderStage.assembled, 'Assembled'),
      (OrderStage.glazed, 'Glazed'),
      (OrderStage.readyForDispatch, 'Ready'),
    ];

    int activeIdx = switch (activeStage) {
      OrderStage.submitted || OrderStage.cut => 0,
      OrderStage.assembled => 1,
      OrderStage.glazed => 2,
      OrderStage.readyForDispatch || OrderStage.completed => 3,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.slateTintSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRODUCTION STAGE TARGET',
                style: AppTheme.monoStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.mutedZinc,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                leadTimeLabel,
                style: AppTheme.monoStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.obsidianBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0)
                  Text(
                    '→',
                    style: AppTheme.monoStyle(
                      fontSize: 10,
                      color: AppPalette.borderMedium,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= activeIdx
                            ? AppPalette.obsidianBlack
                            : AppPalette.borderMedium.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      stages[i].$2,
                      style: AppTheme.monoStyle(
                        fontSize: 10.5,
                        fontWeight:
                            i == activeIdx ? FontWeight.w800 : FontWeight.w600,
                        color: i == activeIdx
                            ? AppPalette.obsidianBlack
                            : AppPalette.mutedZinc,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtworkSpecCard extends StatelessWidget {
  const _ArtworkSpecCard({
    required this.order,
    required this.onDownloadPdfTap,
  });

  final OrderExampleItem order;
  final VoidCallback onDownloadPdfTap;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Moulding ID', order.mouldingLabel),
      ('Mount style', order.mountStyle),
      ('Margins (mm)', order.marginsMm),
      ('Reveal depth', order.revealDepth),
      ('Bevel depth', order.bevelDepth),
      ('Glazing spec', order.glazingSpec),
      ('Backing board', order.backingBoard),
      ('Hanging hardware', order.hangingHardware),
      ('Quantity', order.quantityLabel),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Artwork Header Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.slateTintSurface,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                // [ ART ] crossed placeholder box
                Container(
                  width: 58,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE4F2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppPalette.borderLight),
                  ),
                  child: CustomPaint(
                    painter: const _ArtCrossLinesPainter(),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'ART',
                          style: AppTheme.monoStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.obsidianBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.artworkTitle,
                              style: const TextStyle(
                                color: AppPalette.obsidianBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.obsidianBlack,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              order.itemBadge,
                              style: AppTheme.monoStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.artworkSizeLabel,
                        style: AppTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.coolSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.outerSizeLabel,
                        style: AppTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.obsidianBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Spec key-value table rows (ends at Quantity for Active Orders)
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppPalette.surfaceLight.withValues(alpha: 0.7)
                    : AppPalette.background,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      color: AppPalette.mutedZinc,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.obsidianBlack,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Past Order only: 100% Full-Width [ Download PDF ] Button
          if (order.isPastOrder) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: TextButton.icon(
                onPressed: onDownloadPdfTap,
                icon: const Icon(
                  Icons.download_rounded,
                  size: 17,
                  color: AppPalette.obsidianBlack,
                ),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(
                    color: AppPalette.obsidianBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppPalette.slateTintSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtCrossLinesPainter extends CustomPainter {
  const _ArtCrossLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.borderMedium.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
