import 'dart:ui';

class CropBoxUtils {
  static int mapOrientationToTurn(int orientation) {
    switch (orientation) {
      case 90:
        return 1;
      case 180:
        return 2;
      case 270:
        return 3;
      case -90:
        return -1;
      case -180:
        return -2;
      case -270:
        return -3;
      default:
        return 0;
    }
  }

  static  Size mapSize(double w, double h, int orientation) {
    if ([90, 270, -90, -270].contains(orientation)) return Size(h, w);
    return Size(w, h);
  }
}