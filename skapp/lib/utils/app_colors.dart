import 'package:flutter/material.dart';

const Color kTrialColor = Colors.white;
const Color kSecondaryColor = Colors.amber;
const Color kAccentColor = Colors.green;
const Color KPureWhite = Colors.white;
const Color KPureBlack = Colors.black;
const Color? KDeepPurple400 = Color(0xFF7E57C2);//deeppurple[400]
const Color? KDeepPurpleAccent100 = Color(0xFFB388FF);
// const Color? KDeep
// To add a new color:
// 1. Add a new final Color field (e.g., secondary)
// 2. Update the constructor, copyWith, and lerp methods
// 3. Add the color in your ThemeData extensions in main.dart

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color trial;
  final Color? secondary;
  final Color? accent;
  final Color? textColor;
  final Color? iconColor;
  final Color? shadowColor;
  final Color? borderColor;
  final Color? cardColor;
  final Color? selectedNavColor;
  final Color? unselectedNavColor;
  final Color? inverseColor;

  const AppColorScheme({
    required this.trial,
    this.secondary,
    this.accent,
    this.textColor,
    this.iconColor,
    this.shadowColor,
    this.borderColor,
    this.cardColor,
    this.selectedNavColor,
    this.unselectedNavColor,
    this.inverseColor,
  });

  @override
  AppColorScheme copyWith({
    Color? trial, 
    Color? secondary, 
    Color? accent,
    Color? textColor,
    Color? iconColor,
    Color? shadowColor,
    Color? borderColor,
    Color? cardColor,
    Color? selectedNavColor,
    Color? unselectedNavColor,
    Color? inverseColor,
  }) {
    return AppColorScheme(
      trial: trial ?? this.trial,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textColor: textColor ?? this.textColor,
      iconColor: iconColor ?? this.iconColor,
      shadowColor: shadowColor ?? this.shadowColor,
      borderColor: borderColor ?? this.borderColor,
      cardColor: cardColor ?? this.cardColor,
      selectedNavColor: selectedNavColor ?? this.selectedNavColor,
      unselectedNavColor: unselectedNavColor ?? this.unselectedNavColor,
      inverseColor: inverseColor ?? this.inverseColor,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      trial: Color.lerp(trial, other.trial, t)!,
      secondary: Color.lerp(secondary, other.secondary, t),
      accent: Color.lerp(accent, other.accent, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      cardColor: Color.lerp(cardColor, other.cardColor, t),
      selectedNavColor: Color.lerp(selectedNavColor, other.selectedNavColor, t),
      unselectedNavColor: Color.lerp(unselectedNavColor, other.unselectedNavColor, t),
      inverseColor: Color.lerp(inverseColor, other.inverseColor, t),
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




// Helper
// color: widget.selectedIndex == index
//                                     ? (Theme.of(context).brightness == Brightness.light 
//                                         ? Theme.of(context).colorScheme.inversePrimary
//                                         : appColors.selectedNavColor!)
//                                     : appColors.unselectedNavColor,