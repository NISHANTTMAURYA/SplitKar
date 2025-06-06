import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final bool isButtonLoader;

  const CustomLoader({
    Key? key,
    this.size = 50.0,  // Increased button loader size
    this.isButtonLoader = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveSize = isButtonLoader ? size : screenWidth * 0.6; // 60% of screen width for full loader

    return FutureBuilder(
      future: _loadAnimation(context),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error loading animation: ${snapshot.error}');
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return Center(
          child: Lottie.asset(
            snapshot.data!,
            width: responsiveSize,
            height: responsiveSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('Lottie error: $error');
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        );
      },
    );
  }

  Future<String> _loadAnimation(BuildContext context) async {
    try {
      final path = isButtonLoader ? 'assets/loaders/loader4.json' : 'assets/images/loader3.json';
      // Verify the asset exists
      await DefaultAssetBundle.of(context).load(path);
      return path;
    } catch (e) {
      print('Error loading animation asset: $e');
      rethrow;
    }
  }
} 