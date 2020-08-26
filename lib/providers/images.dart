import 'package:flutter/cupertino.dart';

class Images with ChangeNotifier {
  String images = '';

  void changeImages(String images) {
    this.images = images;
    notifyListeners();
  }
}
