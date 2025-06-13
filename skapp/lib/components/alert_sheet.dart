/*
 * Alert Sheet Component
 * -------------------
 * This component handles the UI presentation of all alerts in the app.
 * 
 * COMPONENT STRUCTURE:
 * ==================
 * 1. Main Components:
 *    - AlertSheet: Bottom sheet container
 *    - AlertList: List of alerts grouped by category
 *    - AlertCard: Individual alert display
 * 
 * HOW TO MODIFY:
 * =============
 * 
 * 1. Styling Alert Cards:
 *    - Find _buildAlertCard method
 *    - Modify the Card widget properties
 *    - Update colors, spacing, animations
 *    Example:
 *    ```
 *    Card(
 *      elevation: 2,
 *      shape: RoundedRectangleBorder(...),
 *      child: YourCustomContent(),
 *    )
 *    ```
 * 
 * 2. Adding New Alert Types:
 *    - Add case in _buildAlertContent
 *    - Create custom layout for new type
 *    Example:
 *    ```
 *    case AlertCategory.newType:
 *      return NewTypeAlertContent(
 *        alert: alert,
 *        onAction: handleAction,
 *      );
 *    ```
 * 
 * 3. Modifying Animations:
 *    - Update AnimatedContainer durations
 *    - Modify transition curves
 *    - Adjust Hero animations
 * 
 * 4. Alert Actions:
 *    - Add new action buttons in _buildActions
 *    - Handle new action types
 *    - Update action styling
 * 
 * 5. Layout Changes:
 *    - Modify DraggableScrollableSheet properties
 *    - Update padding and margins
 *    - Adjust list view parameters
 * 
 * BEST PRACTICES:
 * =============
 * - Keep UI consistent across alert types
 * - Use theme colors for consistency
 * - Handle all screen sizes
 * - Add proper error states
 * - Include loading indicators
 * - Maintain accessibility
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:skapp/pages/groups/group_provider.dart';
import 'package:skapp/pages/friends/freinds.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/bottom_sheet_wrapper.dart';
import '../widgets/custom_loader.dart';
import 'package:logging/logging.dart';
import 'package:skapp/pages/main_page.dart';

// Category count model for UI
class AlertCategoryCount {
  final AlertCategory category;
  final int total;
  final int unread;

  AlertCategoryCount({
    required this.category,
    required this.total,
    required this.unread,
  });

  factory AlertCategoryCount.fromJson(Map<String, dynamic> json) {
    return AlertCategoryCount(
      category: AlertCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
    );
  }
}

// Keep these models as they define UI structure
class AlertItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final List<AlertAction> actions;
  final DateTime timestamp;
  final AlertCategory category;
  final bool requiresResponse;
  final bool isRead;  // Only used for static alerts

  AlertItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.icon,
    required this.actions,
    required this.timestamp,
    this.category = AlertCategory.general,
    this.requiresResponse = false,
    this.isRead = false,
  });

  // Add factory method for backend data
  factory AlertItem.fromJson(Map<String, dynamic> json) {
    // TODO: Implement conversion from backend JSON
    throw UnimplementedError();
  }

  // Helper method to determine if alert should be shown
  bool get shouldShow {
    // For responsive alerts (like friend requests), show if not responded
    if (requiresResponse) {
      return true; // Will be removed once response is given
    }
    // For static alerts, show if not read
    return !isRead;
  }
}

class AlertAction {
  final String label;
  final Future<void> Function() onPressed;
  final Color? color;

  AlertAction({required this.label, required this.onPressed, this.color});
}

// Keep enum for UI organization
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
  final AlertService alertService;
  final VoidCallback? onClose;
  static final _logger = Logger('AlertSheet');

  const AlertSheet({
    super.key, 
    required this.alertService,
    this.onClose,
  });

  static Future<void> show(BuildContext context) {
    return BottomSheetWrapper.show(
      context: context,
      child: Builder(
        builder: (context) {
          final alertService = Provider.of<AlertService>(context, listen: false);
          return AlertSheet(alertService: alertService);
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
  static final _logger = Logger('AlertSheet');

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    // Get categories that have alerts
    final categories = widget.alertService.categoryCounts
      .where((count) => count.total > 0)
      .map((count) => count.category)
      .toList()
      ..sort((a, b) {
        // Sort by responsive alerts first, then by unread count
        final aHasResponse = widget.alertService.alerts.any(
          (alert) => alert.category == a && alert.requiresResponse,
        );
        final bHasResponse = widget.alertService.alerts.any(
          (alert) => alert.category == b && alert.requiresResponse,
        );
        if (aHasResponse != bHasResponse) {
          return aHasResponse ? -1 : 1;
        }
        // Then sort by unread count
        final aCount = widget.alertService.categoryCounts
          .firstWhere((c) => c.category == a)
          .unread;
        final bCount = widget.alertService.categoryCounts
          .firstWhere((c) => c.category == b)
          .unread;
        return bCount.compareTo(aCount);
      });

    // Create tabs list including "All" tab
    final tabs = ['All', ...categories.map((c) => c.displayName)];
    
    // Initialize controller with correct length
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    // Get categories that have alerts
    final categories = widget.alertService.categoryCounts
      .where((count) => count.total > 0)
      .map((count) => count.category)
      .toList();

    return [
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.all_inbox, size: 16),
            const SizedBox(width: 4),
            const Text('All'),
            if (widget.alertService.totalCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.alertService.totalCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ...categories.map((category) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16),
            const SizedBox(width: 4),
            Text(category.displayName),
            if (widget.alertService.categoryCounts
                .firstWhere((c) => c.category == category)
                .unread > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.alertService.categoryCounts
                    .firstWhere((c) => c.category == category)
                    .unread
                    .toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertService>(
      builder: (context, alertService, child) {
        // Show loading state
        if (alertService.isLoading) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomLoader(size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Loading alerts...',
                    style: GoogleFonts.cabin(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (alertService.error != null) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading alerts',
                      style: GoogleFonts.cabin(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alertService.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cabin(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => alertService.fetchAlerts(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Activity',
                      style: GoogleFonts.cabin(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (alertService.alerts.isNotEmpty)
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

              Expanded(
                child: _buildAlertList(context, alertService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertList(BuildContext context, AlertService alertService) {
    if (alertService.alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
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
              style: GoogleFonts.cabin(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Filter alerts by selected category and visibility
    final filteredAlerts = _selectedFilter == null
        ? alertService.alerts.where((a) => a.shouldShow).toList()
        : alertService.alerts.where((a) => a.category == _selectedFilter && a.shouldShow).toList();

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Text(
          'No alerts in this category',
          style: GoogleFonts.cabin(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    // Group alerts by category
    final Map<AlertCategory, List<AlertItem>> groupedAlerts = {};
    for (var alert in filteredAlerts) {
      if (!groupedAlerts.containsKey(alert.category)) {
        groupedAlerts[alert.category] = [];
      }
      groupedAlerts[alert.category]!.add(alert);
    }

    // Sort categories
    final sortedCategories = groupedAlerts.keys.toList()
      ..sort((a, b) {
        final aHasResponse = groupedAlerts[a]!.any((item) => item.requiresResponse);
        final bHasResponse = groupedAlerts[b]!.any((item) => item.requiresResponse);
        if (aHasResponse != bHasResponse) {
          return aHasResponse ? -1 : 1;
        }
        return a.index.compareTo(b.index);
      });

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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
            ...categoryAlerts.map(
              (alert) => _buildAlertCard(context, alert, alertService),
            ),
            if (categoryIndex < sortedCategories.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertItem alert, AlertService alertService) {
    final isProcessing = alertService.isProcessing(alert.id);

    return Hero(
      tag: 'alert_${alert.id}',
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: isProcessing ? const Offset(-1.0, 0.0) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isProcessing ? 0.0 : 1.0,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Card(
              key: ValueKey(alert.id),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: alert.requiresResponse
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : (alert.isRead
                          ? Theme.of(context).cardColor
                          : Theme.of(context).colorScheme.primary.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: alert.imageUrl != null && alert.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: alert.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Icon(
                                        alert.icon,
                                        color: Theme.of(context).colorScheme.primary,
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
                          if (!alert.isRead && !alert.requiresResponse)
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.subtitle,
                            style: GoogleFonts.cabin(
                              color: Theme.of(context).colorScheme.onBackground,
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
                    ),
                    if (alert.actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: alert.actions.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextButton.icon(
                                onPressed: isProcessing ? null : action.onPressed,
                                style: TextButton.styleFrom(
                                  foregroundColor: action.color,
                                ),
                                icon: isProcessing 
                                  ? const CustomLoader(size: 16, isButtonLoader: true)
                                  : Icon(action.label == 'Accept' ? Icons.check : Icons.close),
                                label: Text(action.label),
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
