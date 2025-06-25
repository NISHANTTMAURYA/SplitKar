import 'package:flutter/material.dart';
// need to add 2 border color
// need to add textcolor2
//need to add subtitlecolor 1 and 2
//need to add iconcolor2

const Color kTrialColor = Colors.white;
const Color kSecondaryColor = Colors.amber;
const Color kAccentColor = Colors.green;
const Color KPureWhite = Colors.white;
const Color KPureBlack = Colors.black;
const Color? KDeepPurple400 = Color(0xFF7E57C2);//deeppurple[400]
const Color? KDeepPurpleAccent100 = Color(0xFFB388FF);
const Color? ColorMoredarkerThanScaffold = Color(0xFF6A4795);
const Color? backgroundColordarkmode = Color(0xFF2A203D);

// const Color? KDeep
// To add a new color:
// 1. Add a new final Color field (e.g., secondary)
// 2. Update the constructor, copyWith, and lerp methods
// 3. Add the color in your ThemeData extensions in main.dart




@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color? backgroundColor;
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
  final Color? cardColor2;
  final Color? appBarColor;

  const AppColorScheme({
    this.backgroundColor,
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
    this.cardColor2,
    this.appBarColor,
  });

  @override
  AppColorScheme copyWith({
    Color? backgroundColor,
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
    Color? cardColor2,
    Color? appBarColor,
  }) {
    return AppColorScheme(
      backgroundColor: backgroundColor??this.backgroundColor,
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
      cardColor2: cardColor2 ?? this.cardColor2,
      appBarColor: appBarColor ?? this.appBarColor,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
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
      cardColor2: Color.lerp(cardColor2, other.cardColor2, t),
      appBarColor: Color.lerp(appBarColor, other.appBarColor, t),
    );
  }

  

  // Generalized dynamic color getter
  Color getDynamicColor(BuildContext context, String colorKey) {
    final brightness = Theme.of(context).brightness;
    switch (colorKey) {
      case 'inversePrimary':
        return Theme.of(context).colorScheme.inversePrimary;
      
      // Add more cases for other dynamic colors
      default:
        // Fallback to a neutral color or throw
        return Colors.grey;
    }
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