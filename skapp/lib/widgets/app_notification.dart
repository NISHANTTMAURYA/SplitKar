import 'package:flutter/material.dart';
import 'dart:async';

/// A modern, customizable notification widget that supports two types of notifications:
/// 
/// 1. Regular Notifications (isImportant: false):
///    - Auto-dismisses after 3 seconds
///    - Can be swiped left/right to dismiss
///    - Can be tapped to dismiss
///    - Shows grey close button
///    Example usage:
///    ```dart
///    NotificationService().showAppNotification(
///      context,
///      title: 'Profile Updated',
///      message: 'Your changes have been saved',
///      icon: Icons.check_circle,
///      isImportant: false,  // or omit since false is default
///    );
///    ```
///
/// 2. Important Notifications (isImportant: true):
///    - Stays until manually dismissed
///    - Cannot be swiped away
///    - Must be closed using the purple close button
///    - Used for critical information
///    Example usage:
///    ```dart
///    NotificationService().showAppNotification(
///      context,
///      title: 'New Friend Request',
///      message: 'John Doe wants to connect',
///      icon: Icons.person_add,
///      isImportant: true,
///    );
///    ```
///
/// Preset Notification Methods Available:
/// ```dart
/// // Success notification (auto-dismisses)
/// NotificationService().showSuccessNotification(
///   context,
///   'Operation completed successfully'
/// );
///
/// // Error notification (important, stays)
/// NotificationService().showErrorNotification(
///   context,
///   'Please check your connection'
/// );
///
/// // Warning notification (auto-dismisses)
/// NotificationService().showWarningNotification(
///   context,
///   'Battery is running low'
/// );
///
/// // Friend request (important, stays)
/// NotificationService().showFriendRequestNotification(
///   context,
///   'John Doe'
/// );
///
/// // Message notification (auto-dismisses)
/// NotificationService().showNewMessageNotification(
///   context,
///   'John Doe',
///   'Hey, how are you?'
/// );
/// ```
class AppNotification extends StatefulWidget {
  /// The main message text of the notification
  final String message;
  
  /// Optional title shown in bold above the message
  final String? title;
  
  /// Optional icon shown on the left side
  final IconData? icon;
  
  /// Callback function called when notification is dismissed
  final VoidCallback? onDismissed;
  
  /// Duration before auto-dismiss (only for non-important notifications)
  /// Default is 3 seconds
  final Duration duration;
  
  /// If true:
  /// - Notification won't auto-dismiss
  /// - Can't be swiped away
  /// - Shows purple close button
  /// If false:
  /// - Auto-dismisses after [duration]
  /// - Can be swiped away
  /// - Shows grey close button
  final bool isImportant;

  const AppNotification({
    Key? key,
    required this.message,
    this.title,
    this.icon,
    this.onDismissed,
    this.duration = const Duration(seconds: 3),
    this.isImportant = false,
  }) : super(key: key);

  @override
  State<AppNotification> createState() => _AppNotificationState();
}

class _AppNotificationState extends State<AppNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    if (!widget.isImportant) {
      _autoHideTimer = Timer(widget.duration, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() async {
    if (!mounted) return;
    
    _autoHideTimer?.cancel();
    
    try {
      await _controller.reverse();
      if (mounted) {
        widget.onDismissed?.call();
      }
    } catch (e) {
      // Handle any animation errors silently
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Dismissible(
            key: UniqueKey(),
            direction: widget.isImportant 
                ? DismissDirection.none 
                : DismissDirection.horizontal,
            onDismissed: (direction) {
              _dismiss();
            },
            background: const SizedBox.shrink(),
            secondaryBackground: const SizedBox.shrink(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.isImportant ? null : _dismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.deepPurple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null) ...[
                                Text(
                                  widget.title!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.isImportant 
                                ? Colors.deepPurple.withOpacity(0.1)
                                : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.close,
                              color: widget.isImportant 
                                ? Colors.deepPurple
                                : Colors.grey[400],
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 