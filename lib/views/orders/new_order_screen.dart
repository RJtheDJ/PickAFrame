import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/catalog_moulding.dart';
import '../../models/design_summary.dart';
import '../../models/draft.dart';
import '../../models/ids.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';

/// Sends one of the user's saved drafts to a workshop. When the draft uses a
/// shop's catalogue moulding, that shop is suggested and the price estimated;
/// the workshop confirms the final quote.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  late final _deps = AppScope.of(context);
  late final String? _uid = _deps.auth.currentUser?.uid;
  late final Stream<List<Draft>>? _drafts = _uid == null ? null : _deps.drafts.watchDrafts(_uid);
  late final Stream<List<Vendor>> _vendors = _deps.vendors.watchVendors();
  late final Stream<List<CatalogMoulding>> _mouldings = _deps.mouldings.watchMouldings();

  String? _draftId;
  String? _vendorId;
  bool _submitting = false;

  Future<void> _submit(Draft draft, Vendor vendor, double? estimate) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await _deps.orders.submitOrder(FramingOrder(
        id: newId('o'),
        draftId: draft.id,
        customerUid: _uid!,
        vendorId: vendor.id,
        title: draft.title,
        specLines: describeDesign(draft.design),
        design: draft.design,
        estimateRm: estimate,
        createdAt: DateTime.now(),
      ));
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Order sent to ${vendor.name}')));
    } catch (e) {
      debugPrint('Order failed: $e');
      messenger.showSnackBar(SnackBar(content: Text("Couldn't send the order: $e")));
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('New order'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.obsidianBlack,
      ),
      body: _drafts == null
          ? const Center(child: Text('Sign in to place orders.'))
          : StreamBuilder<List<Draft>>(
              stream: _drafts,
              builder: (context, draftSnap) => StreamBuilder<List<Vendor>>(
                stream: _vendors,
                builder: (context, vendorSnap) => StreamBuilder<List<CatalogMoulding>>(
                  stream: _mouldings,
                  builder: (context, mouldingSnap) {
                    if (draftSnap.hasError || vendorSnap.hasError) {
                      return const Center(child: Text("Couldn't load your drafts or the workshops."));
                    }
                    final drafts = draftSnap.data;
                    final vendors = vendorSnap.data;
                    if (drafts == null || vendors == null) return const Center(child: CircularProgressIndicator());
                    if (drafts.isEmpty) {
                      return const _Message('Save a framed artwork as a draft first, then order it here.');
                    }
                    if (vendors.isEmpty) return const _Message('No workshops are listed yet.');
                    return _form(drafts, vendors, mouldingSnap.data ?? const []);
                  },
                ),
              ),
            ),
    );
  }

  Widget _form(List<Draft> drafts, List<Vendor> vendors, List<CatalogMoulding> mouldings) {
    final draft = drafts.where((d) => d.id == _draftId).firstOrNull ?? drafts.first;
    final catalogId = draft.design.moulding.catalogId;
    final moulding = mouldings.where((m) => m.id == catalogId).firstOrNull;
    // Suggest the shop that sells the draft's moulding.
    final vendor = vendors.where((v) => v.id == (_vendorId ?? moulding?.vendorId)).firstOrNull ?? vendors.first;
    final estimate = moulding != null && moulding.vendorId == vendor.id ? moulding.priceFor(draft.design) : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: draft.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Draft'),
              items: [
                for (final d in drafts) DropdownMenuItem(value: d.id, child: Text(d.title, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (id) => setState(() {
                _draftId = id;
                _vendorId = null; // re-suggest for the new draft
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('vendor-${draft.id}'),
              initialValue: vendor.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Workshop'),
              items: [
                for (final v in vendors)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      v.id == moulding?.vendorId ? '${v.name} (sells this moulding)' : v.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => _vendorId = id),
            ),
            const SizedBox(height: 20),
            const Text('Specification', style: TextStyle(fontWeight: FontWeight.w800, color: AppPalette.obsidianBlack)),
            const SizedBox(height: 6),
            for (final (label, value) in describeDesign(draft.design))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppPalette.mutedZinc))),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              estimate != null
                  ? 'Estimated moulding price: RM ${estimate.toStringAsFixed(2)}'
                  : moulding != null
                      ? 'This workshop doesn\'t list this moulding; they will quote.'
                      : 'Custom frame: the workshop will quote.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'The workshop confirms the final price. Payment is arranged with them directly.',
              style: TextStyle(color: AppPalette.mutedZinc, fontSize: 12),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.obsidianBlack,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _submitting ? null : () => _submit(draft, vendor, estimate),
              child: Text(_submitting ? 'Sending…' : 'Send order to ${vendor.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.coolSlate)),
        ),
      );
}
