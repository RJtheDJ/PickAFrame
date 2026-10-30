import 'dart:math';

final _random = Random.secure();

/// A new document id: time-ordered, plus randomness so two phones creating
/// documents at the same moment never collide. [prefix] marks the kind.
String newId(String prefix) =>
    '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
    '${_random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}';
