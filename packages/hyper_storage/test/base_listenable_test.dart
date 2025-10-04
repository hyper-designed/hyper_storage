
import 'package:hyper_storage/src/api/listenable.dart';
import 'package:test/test.dart';

class ListenableClass with BaseListenable {
  void triggerListeners() {
    notifyListeners();
  }
}

void main() {
  group('BaseListenable', () {
    late ListenableClass listenable;

    setUp(() {
      listenable = ListenableClass();
    });

    test('hasListeners returns false initially', () {
      expect(listenable.hasListeners, isFalse);
    });

    test('addListener adds a listener', () {
      int callCount = 0;
      void listener() => callCount++;

      listenable.addListener(listener);
      expect(listenable.hasListeners, isTrue);

      listenable.triggerListeners();
      expect(callCount, 1);
    });

    test('removeListener removes a listener', () {
      int callCount = 0;
      void listener() => callCount++;

      listenable.addListener(listener);
      listenable.removeListener(listener);
      expect(listenable.hasListeners, isFalse);

      listenable.triggerListeners();
      expect(callCount, 0);
    });

    test('removeAllListeners removes all listeners', () {
      int callCount1 = 0;
      void listener1() => callCount1++;
      int callCount2 = 0;
      void listener2() => callCount2++;

      listenable.addListener(listener1);
      listenable.addListener(listener2);
      listenable.removeAllListeners();
      expect(listenable.hasListeners, isFalse);

      listenable.triggerListeners();
      expect(callCount1, 0);
      expect(callCount2, 0);
    });

    test('notifyListeners calls all listeners', () {
      int callCount1 = 0;
      void listener1() => callCount1++;
      int callCount2 = 0;
      void listener2() => callCount2++;

      listenable.addListener(listener1);
      listenable.addListener(listener2);

      listenable.triggerListeners();
      expect(callCount1, 1);
      expect(callCount2, 1);
    });

    test('listener exception does not break other listeners', () {
      int callCount = 0;
      void listener1() => callCount++;
      void listener2() => throw Exception('test exception');
      void listener3() => callCount++;

      listenable.addListener(listener1);
      listenable.addListener(listener2);
      listenable.addListener(listener3);

      expect(() => listenable.triggerListeners(), returnsNormally);
      expect(callCount, 2);
    });
  });
}
