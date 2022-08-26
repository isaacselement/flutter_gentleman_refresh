// ignore_for_file: avoid_print

class GLog {
  static bool enable = true;

  static void d(String message, {String? tag}) {
    assert(() {
      __print__('${DateTime.now()}: [${tag ?? GLog}] $message');
      return true;
    }());
  }

  /// https://dart.dev/guides/language/language-tour#assert
  /// Only print and evaluate the expression function on debug mode, will omit in production/profile mode
  static void console(String Function() expr) {
    assert(() {
      __print__('${DateTime.now()}: ${expr()}');
      return true;
    }());
  }

  static void __print__(String log) {
    if (enable) {
      print(log);
    }
  }
}
