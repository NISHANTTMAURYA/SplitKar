import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final bool isButtonLoader;

  const CustomLoader({
    Key? key,
    this.size = 48.0,  // Increased button loader size
    this.isButtonLoader = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveSize = isButtonLoader ? size : screenWidth * 0.6; // 60% of screen width for full loader

    return Lottie.asset(
      isButtonLoader ? 'assets/loaders/loader1.json' : 'assets/loaders/loader2.json',
      width: responsiveSize,
      height: responsiveSize,
      fit: BoxFit.contain,
    );
  }
} 