import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../data/finish_catalog.dart';
import '../../models/catalog_moulding.dart';
import '../../models/frame_finish.dart';
import '../../models/frame_profile.dart';
import '../../models/ids.dart';

/// Adds or edits one of a frame shop's mouldings. Limits match
/// firebase/firestore.rules, so anything this form accepts the server accepts.
class MouldingFormScreen extends StatefulWidget {
  const MouldingFormScreen({super.key, required this.vendorId, this.existing});

  final String vendorId;
  final CatalogMoulding? existing;

  @override
  State<MouldingFormScreen> createState() => _MouldingFormScreenState();
}

class _MouldingFormScreenState extends State<MouldingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _width = TextEditingController(text: _number(widget.existing?.faceWidthMm ?? 30));
  late final _rebate = TextEditingController(text: _number(widget.existing?.rebateDepthMm ?? 12));
  late final _price = TextEditingController(text: _number(widget.existing?.pricePerMetreRm ?? 30));
  late String _material = widget.existing?.materialClass ?? mouldingMaterialClasses.first;
  late FrameProfile _profile = widget.existing?.profile ?? FrameProfile.flat;
  late FrameFinish _finish = widget.existing?.finish ?? woodFinishes.first;
  bool _saving = false;

  static String _number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toString();

  /// All finishes the editor can draw, with display names.
  static final _finishes = <(String, FrameFinish)>[
    for (final w in woodFinishes) ('Wood · ${w.name}', w),
    for (final m in metalFinishes) ('Metal · ${m.name}', m),
    for (final p in photoMouldings) ('Ornate · ${p.name}', p),
    for (final (i, c) in paintColors.indexed) ('Paint · colour ${i + 1}', ColorFinish(c)),
  ];

  bool _sameFinish(FrameFinish a, FrameFinish b) =>
      identical(a, b) || (a is ColorFinish && b is ColorFinish && a.color == b.color);

  String? _range(String? text, double low, double high) {
    final value = double.tryParse((text ?? '').trim());
    if (value == null) return 'Enter a number';
    if (value < low || value > high) return 'Between ${_number(low)} and ${_number(high)}';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final mouldings = AppScope.of(context).mouldings;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final moulding = CatalogMoulding(
      id: widget.existing?.id ?? newId('m'),
      vendorId: widget.vendorId,
      name: _name.text.trim(),
      profile: _profile,
      finish: _finish,
      faceWidthMm: double.parse(_width.text.trim()),
      rebateDepthMm: double.parse(_rebate.text.trim()),
      pricePerMetreRm: double.parse(_price.text.trim()),
      materialClass: _material,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    try {
      await mouldings.saveMoulding(moulding);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Saved ${moulding.name}')));
    } catch (e) {
      debugPrint('Saving moulding failed: $e');
      messenger.showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _rebate.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    final isOrnate = _finish is PhotoMouldingFinish;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add moulding' : 'Edit moulding'),
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.obsidianBlack,
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _form,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Walnut 35mm'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _material,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: [for (final m in mouldingMaterialClasses) DropdownMenuItem(value: m, child: Text(m))],
                  onChanged: (v) => setState(() => _material = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _finishes.indexWhere((f) => _sameFinish(f.$2, _finish)).clamp(0, _finishes.length - 1),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Looks like',
                    helperText: 'How it is drawn in the visualizer',
                  ),
                  items: [
                    for (final (i, (label, finish)) in _finishes.indexed)
                      DropdownMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, color: finishSwatchColor(finish)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (i) => setState(() => _finish = _finishes[i!].$2),
                ),
                if (!isOrnate) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<FrameProfile>(
                    initialValue: _profile,
                    decoration: const InputDecoration(labelText: 'Profile'),
                    items: [for (final p in FrameProfile.values) DropdownMenuItem(value: p, child: Text(p.label))],
                    onChanged: (v) => setState(() => _profile = v!),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _width,
                  keyboardType: numberKeyboard,
                  inputFormatters: numbers,
                  decoration: const InputDecoration(labelText: 'Face width', suffixText: 'mm'),
                  validator: (v) => _range(v, 5, 300),
                ),
                TextFormField(
                  controller: _rebate,
                  keyboardType: numberKeyboard,
                  inputFormatters: numbers,
                  decoration: const InputDecoration(labelText: 'Rebate depth', suffixText: 'mm'),
                  validator: (v) => _range(v, 0, 100),
                ),
                TextFormField(
                  controller: _price,
                  keyboardType: numberKeyboard,
                  inputFormatters: numbers,
                  decoration: const InputDecoration(labelText: 'Price per metre', prefixText: 'RM '),
                  validator: (v) => _range(v, 0, 10000),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.obsidianBlack,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save moulding'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
