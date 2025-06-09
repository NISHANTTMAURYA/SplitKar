import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateToMain({int? initialIndex}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'initialIndex': initialIndex},
    );
  }

  Future<dynamic> navigateToSettings() {
    return navigatorKey.currentState!.pushNamed('/settings');
  }

  void goBack() {
    navigatorKey.currentState!.pop();
  }

  bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }

  void popUntilMain() {
    navigatorKey.currentState!.popUntil((route) => route.settings.name == '/main');
  }
} 