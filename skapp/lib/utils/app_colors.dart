import 'package:flutter/material.dart';

// To add a new color:
// 1. Add a new final Color field (e.g., secondary)
// 2. Update the constructor, copyWith, and lerp methods
// 3. Add the color in your ThemeData extensions in main.dart

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color trial;
  // Example: add a new color
  final Color? secondary; // <-- Add your new color here

  const AppColorScheme({
    required this.trial,
    this.secondary, // <-- Add to constructor
  });

  @override
  AppColorScheme copyWith({Color? trial, Color? secondary}) {
    return AppColorScheme(
      trial: trial ?? this.trial,
      secondary: secondary ?? this.secondary, // <-- Add here
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      trial: Color.lerp(trial, other.trial, t)!,
      secondary: Color.lerp(secondary, other.secondary, t), // <-- Add here
    );
  }
}

// Usage in main.dart ThemeData extensions:
// extensions: const [
//   AppColorScheme(
//     trial: Colors.white,
//     secondary: Colors.amber, // <-- Set your new color here
//   ),
// ],
