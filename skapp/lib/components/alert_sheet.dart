/*
 * Dynamic Alert System
 * ------------------
 * This system is designed to handle various types of alerts in a flexible and organized way.
 * 
 * Key Features:
 * 1. Categorization: Alerts are automatically grouped by category (friend requests, group invites, etc.)
 * 2. Priority Handling: Alerts requiring response are shown first
 * 3. Extensible: Easy to add new alert types by extending the AlertCategory enum
 * 
 * How to Add New Alert Types:
 * 1. Add a new category to AlertCategory enum if needed
 * 2. Create an AlertItem with:
 *    - Appropriate category
 *    - requiresResponse flag (true if user action needed)
 *    - Relevant actions (buttons/callbacks)
 * 
 * Example Usage:
 * ```dart
 * alertService.addAlert(
 *   AlertItem(
 *     title: 'Group Invitation',
 *     subtitle: 'User invited you to Group',
 *     category: AlertCategory.groupInvite,
 *     requiresResponse: true,
 *     actions: [
 *       AlertAction(label: 'Accept', onPressed: () => ...),
 *       AlertAction(label: 'Decline', onPressed: () => ...),
 *     ],
 *   ),
 * );
 * ```
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/bottom_sheet_wrapper.dart';
import '../widgets/custom_loader.dart';

// Model class for alert items with enhanced categorization support
class AlertItem {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final List<AlertAction> actions;
  final DateTime timestamp;
  final String type;
  final AlertCategory category;    // Category for grouping alerts
  final bool requiresResponse;     // Indicates if user action is required

  AlertItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.icon,
    required this.actions,
    required this.timestamp,
    required this.type,
    this.category = AlertCategory.general,
    this.requiresResponse = false,
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

// Enum for alert categories
enum AlertCategory {
  friendRequest,
  groupInvite,
  general,
  activity;

  String get displayName {
    switch (this) {
      case AlertCategory.friendRequest:
        return 'Friend Requests';
      case AlertCategory.groupInvite:
        return 'Group Invitations';
      case AlertCategory.general:
        return 'General';
      case AlertCategory.activity:
        return 'Activity';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertCategory.friendRequest:
        return Icons.person_add;
      case AlertCategory.groupInvite:
        return Icons.group_add;
      case AlertCategory.general:
        return Icons.notifications;
      case AlertCategory.activity:
        return Icons.local_activity;
    }
  }
}

class AlertSheet extends StatefulWidget {
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
    return BottomSheetWrapper.show(
      context: context,
      child: Builder(
        builder: (context) {
          final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
          friendsProvider.loadPendingRequests(context);
          
          return AlertSheet(
            alerts: alerts,
            onClose: onClose,
          );
        },
      ),
    );
  }

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AlertCategory? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    // Get unique categories from alerts
    final categories = widget.alerts.map((a) => a.category).toSet().toList()
      ..sort((a, b) {
        // Sort categories: actionable first, then by enum order
        final aHasResponse = widget.alerts.any((alert) => 
          alert.category == a && alert.requiresResponse);
        final bHasResponse = widget.alerts.any((alert) => 
          alert.category == b && alert.requiresResponse);
        if (aHasResponse != bHasResponse) {
          return aHasResponse ? -1 : 1;
        }
        return a.index.compareTo(b.index);
      });
    
    // Add 1 for the "All" tab
    _tabController = TabController(
      length: categories.length + 1,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _tabController.index == 0 
              ? null 
              : categories[_tabController.index - 1];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    final categories = widget.alerts.map((a) => a.category).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return [
      // All tab
      const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.all_inbox, size: 16),
            SizedBox(width: 4),
            Text('All'),
          ],
        ),
      ),
      // Category specific tabs
      ...categories.map((category) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16),
            const SizedBox(width: 4),
            Text(category.displayName),
          ],
        ),
      )),
    ];
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
                // Title and mark all as seen button
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
                    if (widget.alerts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          context.read<AlertService>().markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all),
                        label: Text(
                          'Mark all as seen',
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

          // Category filter tabs
          if (widget.alerts.isNotEmpty)
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: _buildTabs(),
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
    if (widget.alerts.isEmpty) {
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

    // Filter alerts by selected category
    final filteredAlerts = _selectedFilter == null
        ? widget.alerts
        : widget.alerts.where((a) => a.category == _selectedFilter).toList();

    // Group alerts by category
    final Map<AlertCategory, List<AlertItem>> groupedAlerts = {};
    for (var alert in filteredAlerts) {
      if (!groupedAlerts.containsKey(alert.category)) {
        groupedAlerts[alert.category] = [];
      }
      groupedAlerts[alert.category]!.add(alert);
    }

    // Sort categories to show actionable items first
    final sortedCategories = groupedAlerts.keys.toList()
      ..sort((a, b) {
        // First, prioritize categories with items requiring response
        final aHasResponse = groupedAlerts[a]!.any((item) => item.requiresResponse);
        final bHasResponse = groupedAlerts[b]!.any((item) => item.requiresResponse);
        if (aHasResponse != bHasResponse) {
          return aHasResponse ? -1 : 1;
        }
        // Then sort by category order
        return a.index.compareTo(b.index);
      });

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Text(
          'No alerts in this category',
          style: GoogleFonts.cabin(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = sortedCategories[categoryIndex];
        final categoryAlerts = groupedAlerts[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFilter == null) ...[
              // Category header (only show in All view)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(category.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      category.displayName,
                      style: GoogleFonts.cabin(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Category alerts
            ...categoryAlerts.map((alert) => _buildAlertCard(context, alert, alertService)),
            if (categoryIndex < sortedCategories.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertItem alert, AlertService alertService) {
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
                                child: CachedNetworkImage(
                                  imageUrl: alert.imageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => CustomLoader(
                                    size: 25,
                                    isButtonLoader: true,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
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