import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final _logger = Logger('NavigationService');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateToMain({int? initialIndex}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'initialIndex': initialIndex},
    );
  }

  Future<dynamic> navigateToSettings() {
    _logger.info('Attempting to navigate to settings');

    // Check if we're already on the settings page
    final currentRoute = ModalRoute.of(
      navigatorKey.currentContext!,
    )?.settings.name;
    _logger.info('Current route: $currentRoute');

    if (currentRoute == '/settings') {
      _logger.info('Already on settings page, not navigating');
      return Future.value();
    }

    _logger.info('Navigating to settings page');
    return navigatorKey.currentState!.pushNamed('/settings');
  }

  void goBack() {
    navigatorKey.currentState!.pop();
  }

  bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }

  void popUntilMain() {
    navigatorKey.currentState!.popUntil(
      (route) => route.settings.name == '/main',
    );
  }

  Future<dynamic> navigateToGroupChat({
    required String chatName,
    required int groupId,
    String? chatImageUrl,
  }) {
    _logger.info('Navigating to group chat: $chatName, ID: $groupId');
    return navigatorKey.currentState!.pushNamed(
      '/group-chat',
      arguments: {
        'chatName': chatName,
        'groupId': groupId,
        'chatImageUrl': chatImageUrl,
      },
    );
  }
}
