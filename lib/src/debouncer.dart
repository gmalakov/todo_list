import 'dart:async';

class DeBouncer {
  final Duration timeout;
  DeBouncer(this.timeout);

  Timer? tim;

  void execute(void Function() f) {
    tim?.cancel();
    tim = Timer(timeout, f);
  }
}