import 'package:flutter/material.dart';
import 'package:skapp/widgets/top_notification.dart';
import 'package:skapp/widgets/app_notification.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static OverlayEntry? _currentNotification;
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void _showNotification(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.deepPurple,
    Duration duration = const Duration(seconds: 3),
    Color textColor = Colors.white,
  }) {
    _currentNotification?.remove();
    _isVisible = true;
    notifyListeners();
    
    final overlay = Overlay.of(context);
    
    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TopNotification(
          message: message,
          backgroundColor: backgroundColor,
          textColor: textColor,
          duration: duration,
          onDismissed: () {
            _currentNotification?.remove();
            _currentNotification = null;
            _isVisible = false;
            notifyListeners();
          },
        ),
      ),
    );

    overlay.insert(_currentNotification!);
  }

  void showAppNotification(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    bool isImportant = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    _currentNotification?.remove();
    _isVisible = true;
    notifyListeners();

    final overlay = Overlay.of(context);

    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: AppNotification(
          message: message,
          title: title,
          icon: icon,
          duration: duration,
          isImportant: isImportant,
          onDismissed: () {
            _currentNotification?.remove();
            _currentNotification = null;
            _isVisible = false;
            notifyListeners();
          },
        ),
      ),
    );

    overlay.insert(_currentNotification!);
  }

  void showFriendRequestNotification(BuildContext context, String friendName) {
    showAppNotification(
      context,
      title: 'New Friend Request',
      message: '$friendName wants to be your friend',
      icon: Icons.person_add,
      isImportant: true,
    );
  }

  void showNewMessageNotification(BuildContext context, String sender, String message) {
    showAppNotification(
      context,
      title: sender,
      message: message,
      icon: Icons.message,
    );
  }

  void showSuccessNotification(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.green,
    );
  }

  void showErrorNotification(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  void showWarningNotification(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.orange,
    );
  }
} 