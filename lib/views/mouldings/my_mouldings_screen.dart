import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../data/finish_catalog.dart';
import '../../data/moulding_starter_set.dart';
import '../../models/catalog_moulding.dart';
import 'moulding_form_screen.dart';

/// A frame shop's own catalogue: add, edit and remove the mouldings it sells.
class MyMouldingsScreen extends StatefulWidget {
  const MyMouldingsScreen({super.key});

  @override
  State<MyMouldingsScreen> createState() => _MyMouldingsScreenState();
}

class _MyMouldingsScreenState extends State<MyMouldingsScreen> {
  late final _deps = AppScope.of(context);
  late final String? _vendorId = _deps.auth.currentUser?.vendorId;
  late final Stream<List<CatalogMoulding>>? _mouldings =
      _vendorId == null ? null : _deps.mouldings.watchVendorMouldings(_vendorId);
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      debugPrint('Moulding update failed: $e');
      messenger.showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addStarterSet() => _run(() async {
        for (final m in starterMouldings(_vendorId!)) {
          await _deps.mouldings.saveMoulding(m);
        }
      }, 'Added 6 starter mouldings. Edit their prices to match your shop.');

  Future<void> _delete(CatalogMoulding moulding) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${moulding.name}?'),
        content: const Text('It disappears from the catalogue. Existing orders keep their details.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) await _run(() => _deps.mouldings.deleteMoulding(moulding.id), 'Removed');
  }

  void _openForm([CatalogMoulding? moulding]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MouldingFormScreen(vendorId: _vendorId!, existing: moulding),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final stream = _mouldings;
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('My mouldings'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.obsidianBlack,
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      floatingActionButton: stream == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppPalette.obsidianBlack,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add moulding'),
              onPressed: _openForm,
            ),
      body: stream == null
          ? const Center(child: Text('Only frame shop accounts can list mouldings.'))
          : StreamBuilder<List<CatalogMoulding>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Couldn't load your mouldings."));
                }
                final mouldings = snapshot.data;
                if (mouldings == null) return const Center(child: CircularProgressIndicator());
                if (mouldings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Your shop has no mouldings listed yet.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Add a starter set of 6'),
                            onPressed: _busy ? null : _addStarterSet,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                      itemCount: mouldings.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppPalette.borderLight),
                      itemBuilder: (context, i) {
                        final m = mouldings[i];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: finishSwatchColor(m.finish), width: 7),
                            ),
                          ),
                          title: Text(m.name),
                          subtitle: Text(
                            '${m.materialClass} · ${m.faceWidthMm.round()} mm · '
                            'RM ${m.pricePerMetreRm.toStringAsFixed(2)}/m',
                          ),
                          onTap: () => _openForm(m),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy ? null : () => _delete(m),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
