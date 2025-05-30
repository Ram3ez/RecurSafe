import 'package:flutter/foundation.dart';

class AppResetNotifier extends ChangeNotifier {
  void notifyReset() {
    notifyListeners();
  }
}
