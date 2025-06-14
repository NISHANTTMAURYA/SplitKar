import 'package:flutter/material.dart';

class MobileUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getScreenRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  // You can add more utility methods here if needed, e.g., for padding based on screen size
  static double getResponsivePadding(BuildContext context, double factor) {
    return getScreenWidth(context) * factor;
  }
}
