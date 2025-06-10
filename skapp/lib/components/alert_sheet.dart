import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/alert_service.dart';

// Model class for alert items
class AlertItem {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final List<AlertAction> actions;
  final DateTime timestamp;
  final String type;

  AlertItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.icon,
    required this.actions,
    required this.timestamp,
    required this.type,
  });
}

// Model class for alert actions
class AlertAction {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  AlertAction({
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class AlertSheet extends StatelessWidget {
  final List<AlertItem> alerts;
  final VoidCallback? onClose;

  const AlertSheet({
    super.key,
    required this.alerts,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AlertItem> alerts,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => AlertSheet(
          alerts: alerts,
          onClose: onClose,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle and title
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Title and clear button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: GoogleFonts.cabin(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (alerts.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          context.read<AlertService>().clearAlerts();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.cabin(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Alert list
          Expanded(
            child: _buildAlertList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No new activity',
              style: GoogleFonts.cabin(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: GoogleFonts.cabin(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final alertService = context.watch<AlertService>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final isRead = alertService.isRead(alert);

        return Hero(
          tag: 'alert_${alert.timestamp.millisecondsSinceEpoch}',
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: isRead ? 1 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => alertService.markAsRead(alert),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isRead 
                      ? Theme.of(context).cardColor
                      : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: alert.imageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      alert.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        alert.icon,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    alert.icon,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                          ),
                          if (!isRead)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        alert.title,
                        style: GoogleFonts.cabin(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.subtitle,
                            style: GoogleFonts.cabin(
                              color: isRead 
                                  ? Colors.grey[600]
                                  : Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(alert.timestamp),
                            style: GoogleFonts.cabin(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    if (alert.actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: alert.actions.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextButton(
                                onPressed: () {
                                  action.onPressed();
                                  alertService.markAsRead(alert);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: action.color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  action.label,
                                  style: GoogleFonts.cabin(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 