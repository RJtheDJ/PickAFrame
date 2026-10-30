import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/repositories/switch_latest.dart';

void main() {
  test('a new outer event is forwarded even though the old inner stream never ends', () async {
    final authStates = StreamController<String?>();
    final profiles = StreamController<String>.broadcast();
    final seen = <String?>[];

    final sub = switchLatest<String?, String?>(
      authStates.stream,
      (user) => user == null ? Stream.value(null) : profiles.stream,
    ).listen(seen.add);

    authStates.add('kahhan');
    await pumpEventQueue();
    profiles.add('kahhan lee');
    await pumpEventQueue();
    authStates.add(null); // signed out; the profile listener is still open
    await pumpEventQueue();

    expect(seen, ['kahhan lee', null]);

    profiles.add('stale update after sign-out');
    await pumpEventQueue();
    expect(seen, ['kahhan lee', null], reason: 'the old listener was cancelled');

    await sub.cancel();
    await authStates.close();
    await profiles.close();
  });
}
