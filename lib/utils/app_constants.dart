import 'package:flutter/material.dart';

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Screen dimensions
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getBaseSize(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    return width < height ? width : height;
  }

  // Colors
  static Color getBarColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface.withOpacity(0.95);
  }

  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).colorScheme.inversePrimary;
  }

  static Color getIconColor() {
    return Colors.grey[600]!;
  }

  static Color getSelectedColor() {
    return Colors.blueAccent;
  }
} 