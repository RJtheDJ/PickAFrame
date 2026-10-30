import 'dart:async';

/// Maps each event of [source] to a stream and forwards only the newest one,
/// cancelling the previous. Unlike [Stream.asyncExpand], which waits for each
/// inner stream to finish first, this works with inner streams that never
/// end (Firestore listeners): a sign-out replaces the old account's profile
/// listener straight away.
Stream<R> switchLatest<T, R>(Stream<T> source, Stream<R> Function(T) convert) {
  StreamSubscription<T>? outer;
  StreamSubscription<R>? inner;
  late final StreamController<R> controller;
  controller = StreamController<R>(
    onListen: () {
      outer = source.listen(
        (event) {
          inner?.cancel();
          inner = convert(event).listen(controller.add, onError: controller.addError);
        },
        onError: controller.addError,
        onDone: () async {
          await inner?.cancel();
          await controller.close();
        },
      );
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );
  return controller.stream;
}
