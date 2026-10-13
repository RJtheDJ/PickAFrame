import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks for the artwork's measured width and height, in centimetres.
/// Returns the size in millimetres, or null if cancelled.
Future<Size?> showArtworkSizeDialog(BuildContext context, Size currentMm) {
  return showDialog<Size>(
    context: context,
    builder: (context) => _ArtworkSizeDialog(currentMm: currentMm),
  );
}

class _ArtworkSizeDialog extends StatefulWidget {
  const _ArtworkSizeDialog({required this.currentMm});

  final Size currentMm;

  @override
  State<_ArtworkSizeDialog> createState() => _ArtworkSizeDialogState();
}

class _ArtworkSizeDialogState extends State<_ArtworkSizeDialog> {
  static const _minCm = 1.0;
  static const _maxCm = 1000.0;

  final _formKey = GlobalKey<FormState>();
  late final _width = TextEditingController(text: _cm(widget.currentMm.width));
  late final _height = TextEditingController(text: _cm(widget.currentMm.height));

  static String _cm(double mm) {
    final text = (mm / 10).toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  static double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validate(String? text) {
    final cm = _parse(text ?? '');
    if (cm == null) return 'Enter a number';
    if (cm < _minCm || cm > _maxCm) return 'Between 1 and 1000 cm';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Size(_parse(_width.text)! * 10, _parse(_height.text)! * 10));
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, TextEditingController controller, TextInputAction action) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, suffixText: 'cm'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        textInputAction: action,
        validator: _validate,
        onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
      );
    }

    return AlertDialog(
      title: const Text('Artwork size'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measure the visible artwork. The photo will be fitted to these exact proportions.',
            ),
            const SizedBox(height: 12),
            field('Width', _width, TextInputAction.next),
            field('Height', _height, TextInputAction.done),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Apply')),
      ],
    );
  }
}
