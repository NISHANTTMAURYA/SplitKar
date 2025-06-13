/*
 * Dynamic Alert System
 * ------------------
 * This system is designed to handle various types of alerts in a flexible and organized way.
 * 
 * Key Features:
 * 1. Categorization: Alerts are automatically grouped by category
 * 2. UI Organization: Alerts requiring response are shown first
 * 3. Backend Integration: Alerts are fetched directly from backend
 * 
 * Alert Types:
 * 1. Static Alerts: 
 *    - Notifications that don't require response
 *    - Stored in database
 *    - Read status tracked in database
 * 
 * 2. Interactive Alerts:
 *    - Friend requests, group invites etc.
 *    - Fetched from separate endpoints
 *    - Actions trigger direct API calls
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
  final List<AlertItem> alerts;
  final List<AlertCategoryCount> categoryCounts;
  final VoidCallback? onClose;
  static final _logger = Logger('AlertSheet');

  const AlertSheet({
    super.key, 
    required this.alerts,
    required this.categoryCounts,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AlertItem> alerts,
    required List<AlertCategoryCount> categoryCounts,
    VoidCallback? onClose,
  }) {
    return BottomSheetWrapper.show(
      context: context,
      child: Builder(
        builder: (context) {
          // Load both friend requests and group invitations
          final friendsProvider = Provider.of<FriendsProvider>(
            context,
            listen: false,
          );
          final groupProvider = Provider.of<GroupProvider>(
            context,
            listen: false,
          );
          final alertService = Provider.of<AlertService>(
            context,
            listen: false,
          );
          
          // Load pending requests and invitations
          Future.wait([
            friendsProvider.loadPendingRequests(context),
            groupProvider.loadPendingInvitations(context),
            alertService.fetchAlerts(context),
          ]).catchError((error) {
            AlertSheet._logger.severe('Error loading alerts: $error');
          });

          return AlertSheet(
            alerts: alerts,
            categoryCounts: categoryCounts,
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
  static final _logger = Logger('AlertSheet');

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    // Get categories that have alerts
    final categories = widget.categoryCounts
      .where((count) => count.total > 0)
      .map((count) => count.category)
      .toList()
      ..sort((a, b) {
        // Sort by responsive alerts first, then by unread count
        final aHasResponse = widget.alerts.any(
          (alert) => alert.category == a && alert.requiresResponse,
        );
        final bHasResponse = widget.alerts.any(
          (alert) => alert.category == b && alert.requiresResponse,
        );
        if (aHasResponse != bHasResponse) {
          return aHasResponse ? -1 : 1;
        }
        // Then sort by unread count
        final aCount = widget.categoryCounts
          .firstWhere((c) => c.category == a)
          .unread;
        final bCount = widget.categoryCounts
          .firstWhere((c) => c.category == b)
          .unread;
        return bCount.compareTo(aCount);
      });

    _tabController = TabController(length: categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    return [
      // All tab with total count
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.all_inbox, size: 16),
            const SizedBox(width: 4),
            const Text('All'),
            if (_getTotalUnreadCount() > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getTotalUnreadCount().toString(),
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
      // Category specific tabs with counts
      ...widget.categoryCounts
        .where((count) => count.total > 0)
        .map((count) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(count.category.icon, size: 16),
              const SizedBox(width: 4),
              Text(count.category.displayName),
              if (count.unread > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.unread.toString(),
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

  int _getTotalUnreadCount() {
    return widget.categoryCounts.fold(0, (sum, count) => sum + count.unread);
  }

  @override
  Widget build(BuildContext context) {
    // Get providers to check loading/error states
    final alertService = Provider.of<AlertService>(context);
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);

    // Show loading state if any provider is loading
    if (alertService.isLoading || 
        friendsProvider.isLoading || 
        groupProvider.isLoadingInvitations) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomLoader(size: 40),
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

    // Show error state if any provider has an error
    final errors = [
      if (alertService.error != null) alertService.error,
      if (friendsProvider.error != null) friendsProvider.error,
      if (groupProvider.invitationError != null) groupProvider.invitationError,
    ];

    if (errors.isNotEmpty) {
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
                  errors.join('\n'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cabin(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // Retry loading alerts
                    alertService.fetchAlerts(context);
                    friendsProvider.loadPendingRequests(context);
                    groupProvider.loadPendingInvitations(context);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show normal content if no loading or errors
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                // Title
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
          Expanded(child: _buildAlertList(context)),
        ],
      ),
    );
  }

  Widget _buildAlertList(BuildContext context) {
    AlertSheet._logger.info('Building alert list with ${widget.alerts.length} alerts');
    AlertSheet._logger.info('Category counts: ${widget.categoryCounts}');

    if (widget.alerts.isEmpty) {
      AlertSheet._logger.info('No alerts to display');
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
        ? widget.alerts.where((a) => a.shouldShow).toList()
        : widget.alerts.where((a) => a.category == _selectedFilter && a.shouldShow).toList();

    AlertSheet._logger.info('Filtered alerts count: ${filteredAlerts.length}');
    AlertSheet._logger.info('Selected filter: $_selectedFilter');

    if (filteredAlerts.isEmpty) {
      AlertSheet._logger.info('No alerts after filtering');
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

    AlertSheet._logger.info('Grouped alerts by category: ${groupedAlerts.keys.map((k) => '${k.name}: ${groupedAlerts[k]!.length}')}');

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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = sortedCategories[categoryIndex];
        final categoryAlerts = groupedAlerts[category]!;

        AlertSheet._logger.info('Building category ${category.name} with ${categoryAlerts.length} alerts');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFilter == null) ...[
              // Category header (only show in All view)
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
            // Category alerts
            ...categoryAlerts.map(
              (alert) => _buildAlertCard(context, alert),
            ),
            if (categoryIndex < sortedCategories.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertItem alert) {
    return Hero(
      tag: 'alert_${alert.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            if (!alert.requiresResponse) {
              context.read<AlertService>().markAsRead(context, alert);
            }
          },
          borderRadius: BorderRadius.circular(12),
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
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
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
                            onPressed: () async {
                              try {
                                // Execute the action
                                await action.onPressed();
                                
                                // Close the sheet
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }

                                // Refresh data using the static method
                                if (context.mounted) {
                                  await MainPage.refreshData(context);
                                }

                                // Refresh both friends and groups lists
                                if (context.mounted) {
                                  final friendsProvider = Provider.of<FriendsProvider>(
                                    context,
                                    listen: false,
                                  );
                                  final groupProvider = Provider.of<GroupProvider>(
                                    context,
                                    listen: false,
                                  );

                                  // Clear caches and force refresh
                                  if (alert.category == AlertCategory.friendRequest) {
                                    await friendsProvider.service.clearCache();
                                    await friendsProvider.service.getFriends(forceRefresh: true);
                                    if (FreindsPage.freindsKey.currentState != null) {
                                      await FreindsPage.freindsKey.currentState!.refreshFriends();
                                    }
                                  }

                                  if (alert.category == AlertCategory.groupInvite) {
                                    await groupProvider.service.clearCache();
                                    await groupProvider.service.getGroups(forceRefresh: true);
                                    await groupProvider.refreshGroups();
                                  }
                                }
                              } catch (e) {
                                AlertSheet._logger.severe('Error executing action: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
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
