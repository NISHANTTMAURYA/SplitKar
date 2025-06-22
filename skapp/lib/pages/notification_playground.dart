import 'package:flutter/material.dart';
import 'package:skapp/widgets/app_notification.dart';

class NotificationPlayground extends StatefulWidget {
  const NotificationPlayground({Key? key}) : super(key: key);

  @override
  State<NotificationPlayground> createState() => _NotificationPlaygroundState();
}

class _NotificationPlaygroundState extends State<NotificationPlayground> {
  OverlayEntry? _notificationEntry;

  void _showNotification({bool isImportant = false}) {
    _notificationEntry?.remove();
    _notificationEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 16,
        right: 16,
        child: AppNotification(
          title: isImportant ? "Important!" : "Hello",
          message: isImportant
              ? "This is an important notification."
              : "This is a regular notification.",
          icon: isImportant ? Icons.warning : Icons.check_circle,
          isImportant: isImportant,
          onDismissed: () {
            _notificationEntry?.remove();
            _notificationEntry = null;
          },
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_notificationEntry!);
  }

  @override
  void dispose() {
    _notificationEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Playground")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _showNotification(isImportant: false),
              child: Text("Show Regular Notification"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showNotification(isImportant: true),
              child: Text("Show Important Notification"),
            ),
          ],
        ),
      ),
    );
  }
}
