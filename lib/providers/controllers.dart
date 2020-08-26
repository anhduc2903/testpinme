import 'package:flutter/cupertino.dart';

class Controllers with ChangeNotifier {
  int controllerIndex = 0;

  void changeIndex(int controllerIndex) {
    this.controllerIndex = controllerIndex;
    notifyListeners();
  }
}
