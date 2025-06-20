import 'package:flutter/material.dart';
import 'package:skapp/main.dart';

class AppColors {
  // Primary Colors
  static Color get primary => isDarkMode.value ? Colors.deepPurple[300]! : Colors.deepPurple;
  static Color get primaryLight => isDarkMode.value ? Colors.deepPurple[200]! : Colors.deepPurple[300]!;
  static Color get primaryDark => isDarkMode.value ? Colors.deepPurple[400]! : Colors.deepPurple[700]!;
  
  // Background Colors
  static Color get background => isDarkMode.value ? Colors.grey[900]! : Colors.white;
  static Color get surface => isDarkMode.value ? Colors.grey[800]! : Colors.grey[50]!;
  static Color get cardBackground => isDarkMode.value ? Colors.grey[850]! : Colors.white;
  
  // Text Colors
  static Color get textPrimary => isDarkMode.value ? Colors.white : Colors.black;
  static Color get textSecondary => isDarkMode.value ? Colors.grey[300]! : Colors.grey[700]!;
  static Color get textTertiary => isDarkMode.value ? Colors.grey[400]! : Colors.grey[600]!;
  static Color get textDisabled => isDarkMode.value ? Colors.grey[500]! : Colors.grey[400]!;
  
  // Border Colors
  static Color get border => isDarkMode.value ? Colors.grey[700]! : Colors.grey[300]!;
  static Color get borderLight => isDarkMode.value ? Colors.grey[600]! : Colors.grey[200]!;
  
  // Status Colors
  static Color get success => isDarkMode.value ? Colors.green[400]! : Colors.green;
  static Color get error => isDarkMode.value ? Colors.red[400]! : Colors.red;
  static Color get warning => isDarkMode.value ? Colors.orange[400]! : Colors.orange;
  static Color get info => isDarkMode.value ? Colors.blue[400]! : Colors.blue;
  
  // Interactive Colors
  static Color get buttonPrimary => isDarkMode.value ? Colors.deepPurple[400]! : Colors.deepPurple;
  static Color get buttonSecondary => isDarkMode.value ? Colors.grey[700]! : Colors.grey[200]!;
  static Color get buttonDisabled => isDarkMode.value ? Colors.grey[600]! : Colors.grey[300]!;
  
  // Shadow Colors
  static Color get shadow => isDarkMode.value ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
  static Color get shadowLight => isDarkMode.value ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05);
  
  // Overlay Colors
  static Color get overlay => isDarkMode.value ? Colors.black.withOpacity(0.8) : Colors.black.withOpacity(0.5);
  static Color get overlayLight => isDarkMode.value ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.3);
  
  // Custom Theme Colors
  static Color get accent => isDarkMode.value ? Colors.purple[300]! : Colors.purple;
  static Color get highlight => isDarkMode.value ? Colors.amber[300]! : Colors.amber;
  static Color get subtle => isDarkMode.value ? Colors.grey[600]! : Colors.grey[100]!;
  
  // Gradient Colors
  static List<Color> get primaryGradient => isDarkMode.value 
    ? [Colors.deepPurple[800]!, Colors.deepPurple[600]!]
    : [Colors.deepPurple, Colors.deepPurple[300]!];
  
  static List<Color> get backgroundGradient => isDarkMode.value
    ? [Colors.grey[900]!, Colors.grey[800]!]
    : [Colors.white, Colors.grey[50]!];
  
  // Icon Colors
  static Color get iconPrimary => isDarkMode.value ? Colors.white : Colors.black;
  static Color get iconSecondary => isDarkMode.value ? Colors.grey[400]! : Colors.grey[600]!;
  static Color get iconAccent => isDarkMode.value ? Colors.deepPurple[300]! : Colors.deepPurple;
  
  // Input Colors
  static Color get inputBackground => isDarkMode.value ? Colors.grey[800]! : Colors.white;
  static Color get inputBorder => isDarkMode.value ? Colors.grey[600]! : Colors.grey[300]!;
  static Color get inputBorderFocused => isDarkMode.value ? Colors.deepPurple[400]! : Colors.deepPurple;
  
  // List Colors
  static Color get listItemBackground => isDarkMode.value ? Colors.grey[850]! : Colors.white;
  static Color get listItemHover => isDarkMode.value ? Colors.grey[800]! : Colors.grey[50]!;
  static Color get listItemSelected => isDarkMode.value ? Colors.deepPurple[800]! : Colors.deepPurple[50]!;
  
  // Divider Colors
  static Color get divider => isDarkMode.value ? Colors.grey[700]! : Colors.grey[300]!;
  static Color get dividerLight => isDarkMode.value ? Colors.grey[600]! : Colors.grey[200]!;
  
  // Loading Colors
  static Color get loadingBackground => isDarkMode.value ? Colors.black : Colors.white;
  static Color get loadingOverlay => isDarkMode.value ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9);
}

// Extension for easy color access
extension ColorExtension on Color {
  Color get withTheme => this;
  
  // Opacity helpers
  Color get light => withOpacity(0.3);
  Color get medium => withOpacity(0.6);
  Color get heavy => withOpacity(0.8);
}

// Theme-aware color builder
class ThemeAwareColor {
  final Color lightColor;
  final Color darkColor;
  
  const ThemeAwareColor({
    required this.lightColor,
    required this.darkColor,
  });
  
  Color get value => isDarkMode.value ? darkColor : lightColor;
  
  Color withOpacity(double opacity) => value.withOpacity(opacity);
}

// Predefined theme-aware colors
class AppThemeColors {
  static const primary = ThemeAwareColor(
    lightColor: Colors.deepPurple,
    darkColor: Color(0xFFB39DDB), // deepPurple[300]
  );
  
  static const background = ThemeAwareColor(
    lightColor: Colors.white,
    darkColor: Color(0xFF212121), // grey[900]
  );
  
  static const text = ThemeAwareColor(
    lightColor: Colors.black,
    darkColor: Colors.white,
  );
  
  static const surface = ThemeAwareColor(
    lightColor: Color(0xFFFAFAFA), // grey[50]
    darkColor: Color(0xFF424242), // grey[800]
  );
  
  static const error = ThemeAwareColor(
    lightColor: Colors.red,
    darkColor: Color(0xFFEF5350), // red[400]
  );
  
  static const success = ThemeAwareColor(
    lightColor: Colors.green,
    darkColor: Color(0xFF66BB6A), // green[400]
  );
} 