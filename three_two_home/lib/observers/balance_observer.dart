// Observer pattern — balance change event bus
abstract class BalanceObserver {
  void onBalanceChanged(double newBalance);
}

class BalanceSubject {
  BalanceSubject._();
  static final BalanceSubject instance = BalanceSubject._();

  final List<BalanceObserver> _observers = [];

  void subscribe(BalanceObserver observer) {
    if (!_observers.contains(observer)) _observers.add(observer);
  }

  void unsubscribe(BalanceObserver observer) {
    _observers.remove(observer);
  }

  void notify(double balance) {
    for (final o in List.of(_observers)) {
      o.onBalanceChanged(balance);
    }
  }
}
