/*
 * Alert Service
 * ------------
 * This service handles all alert-related operations in the app.
 * It serves as the single source of truth for alert state.
 * 
 * HOW TO EXTEND THIS SYSTEM:
 * =========================
 * 
 * 1. Adding a New Alert Type:
 *    a) Add new category to AlertCategory enum
 *    b) Create helper method like _createNewTypeAlert
 *    c) Add handling in fetchAlerts
 *    Example:
 *    ```
 *    enum AlertCategory {
 *      friendRequest,
 *      groupInvite,
 *      newAlertType  // <-- Add here
 *    }
 *    ```
 * 
 * 2. Modifying Alert Appearance:
 *    a) Update _buildAlertCard in alert_sheet.dart
 *    b) Modify styles in respective UI sections
 *    Example:
 *    ```
 *    case AlertCategory.newAlertType:
 *      return CustomAlertCard(
 *        // Custom styling here
 *      );
 *    ```
 * 
 * 3. Adding New Actions:
 *    a) Create new AlertAction instances
 *    b) Add handling in respective provider classes
 *    Example:
 *    ```
 *    AlertAction(
 *      label: 'New Action',
 *      onPressed: () => handleNewAction(),
 *    )
 *    ```
 * 
 * 4. Alert Lifecycle:
 *    - Creation: Through service methods
 *    - Display: Managed by AlertSheet
 *    - Actions: Handled by respective providers
 *    - Cleanup: Automatic through service
 * 
 * 5. Best Practices:
 *    - Keep alert content concise
 *    - Use consistent styling
 *    - Handle all error cases
 *    - Clean up alerts after action
 *    - Log important events
 */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:skapp/config.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/components/alert_sheet.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:skapp/pages/groups/group_provider.dart';
import 'package:provider/provider.dart';

class AlertService extends ChangeNotifier {
  static final _logger = Logger('AlertService');
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  var client = http.Client();

  List<AlertItem> _alerts = [];
  List<AlertCategoryCount> _categoryCounts = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _processingAlerts = {}; // Track alerts being processed

  // Getters
  List<AlertItem> get alerts => _alerts;
  List<AlertCategoryCount> get categoryCounts => _categoryCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isProcessing(String alertId) => _processingAlerts.contains(alertId);
  
  // Get total count of alerts requiring attention
  int get totalCount => _categoryCounts.fold(0, (sum, count) => sum + count.unread);

  // Show alert sheet with current state
  void showAlertSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return AlertSheet(
              alertService: this, // Pass service instead of individual props
              onClose: () => fetchAlerts(context),
            );
          },
        );
      },
    );
  }

  // Helper method to create friend request alert
  AlertItem _createFriendRequestAlert(
    Map<String, dynamic> request,
    FriendsProvider friendsProvider,
    BuildContext context,
  ) {
    return AlertItem(
      id: 'friend_request_${request['request_id']}',
      title: 'Friend Request',
      subtitle: '${request['from_username']} wants to be your friend',
      icon: Icons.person_add,
      actions: [
        AlertAction(
          label: 'Accept',
          onPressed: () => handleAlertAction(
            context,
            'friend_request_${request['request_id']}',
            () => friendsProvider.respondToFriendRequest(
              context,
              request['request_id'].toString(),
              true,
            ),
          ),
          color: Colors.green,
        ),
        AlertAction(
          label: 'Decline',
          onPressed: () => handleAlertAction(
            context,
            'friend_request_${request['request_id']}',
            () => friendsProvider.respondToFriendRequest(
              context,
              request['request_id'].toString(),
              false,
            ),
          ),
          color: Colors.red,
        ),
      ],
      timestamp: DateTime.parse(request['created_at'] ?? DateTime.now().toIso8601String()),
      category: AlertCategory.friendRequest,
      requiresResponse: true,
    );
  }

  // Helper method to create group invitation alert
  AlertItem _createGroupInvitationAlert(
    Map<String, dynamic> invitation,
    GroupProvider groupProvider,
    BuildContext context,
  ) {
    return AlertItem(
      id: 'group_invite_${invitation['invitation_id']}',
      title: 'Group Invitation',
      subtitle: '${invitation['invited_by_username']} invited you to join ${invitation['group_name']}',
      icon: Icons.group_add,
      actions: [
        AlertAction(
          label: 'Accept',
          onPressed: () => handleAlertAction(
            context,
            'group_invite_${invitation['invitation_id']}',
            () => groupProvider.handleInvitationResponse(
              context,
              invitation['invitation_id'],
              true,
            ),
          ),
          color: Colors.green,
        ),
        AlertAction(
          label: 'Decline',
          onPressed: () => handleAlertAction(
            context,
            'group_invite_${invitation['invitation_id']}',
            () => groupProvider.handleInvitationResponse(
              context,
              invitation['invitation_id'],
              false,
            ),
          ),
          color: Colors.red,
        ),
      ],
      timestamp: DateTime.parse(invitation['created_at'] ?? DateTime.now().toIso8601String()),
      category: AlertCategory.groupInvite,
      requiresResponse: true,
    );
  }

  // Handle alert action with optimistic updates
  Future<void> handleAlertAction(
    BuildContext context,
    String alertId,
    Future<void> Function() action,
  ) async {
    if (_processingAlerts.contains(alertId)) return;

    // Store the alert for potential rollback
    final alertToRemove = _alerts.firstWhere((a) => a.id == alertId);
    final originalAlerts = List<AlertItem>.from(_alerts);
    final originalCounts = List<AlertCategoryCount>.from(_categoryCounts);

    try {
      // Start processing in background
      _processingAlerts.add(alertId);
      notifyListeners();

      // Execute the action in background
      await action();

      // After successful action, remove the alert and update counts
      _alerts.removeWhere((a) => a.id == alertId);
      _updateCategoryCounts();
      notifyListeners();

      // If there are no more alerts in the current category, fetch fresh data
      if (_alerts.isEmpty || !_alerts.any((a) => a.category == alertToRemove.category)) {
        await fetchAlerts(context);
      }
    } catch (e) {
      _logger.severe('Error handling alert action: $e');
      
      // Rollback optimistic update on error
      _alerts = originalAlerts;
      _categoryCounts = originalCounts;
      notifyListeners();

      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process action: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      rethrow;
    } finally {
      _processingAlerts.remove(alertId);
      notifyListeners();
    }
  }

  // Update category counts based on current alerts
  void _updateCategoryCounts() {
    final Map<AlertCategory, int> totalCounts = {};
    final Map<AlertCategory, int> unreadCounts = {};

    for (var alert in _alerts) {
      totalCounts[alert.category] = (totalCounts[alert.category] ?? 0) + 1;
      if (!alert.isRead || alert.requiresResponse) {
        unreadCounts[alert.category] = (unreadCounts[alert.category] ?? 0) + 1;
      }
    }

    _categoryCounts = AlertCategory.values.map((category) {
      return AlertCategoryCount(
        category: category,
        total: totalCounts[category] ?? 0,
        unread: unreadCounts[category] ?? 0,
      );
    }).where((count) => count.total > 0).toList();

    notifyListeners();
  }

  // Fetch alerts from backend
  Future<void> fetchAlerts(BuildContext context) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      _logger.info('Fetching friend requests and group invitations...');

      final friendRequests = await friendsProvider.service.getPendingFriendRequests();
      final groupInvitations = await groupProvider.service.getPendingInvitations();

      List<AlertItem> newAlerts = [];

      if (friendRequests != null && friendRequests['received_requests'] != null) {
        for (var request in friendRequests['received_requests']) {
          if (request != null && request['request_id'] != null && request['from_username'] != null) {
            newAlerts.add(_createFriendRequestAlert(request, friendsProvider, context));
          }
        }
      }

      if (groupInvitations != null && groupInvitations['received_invitations'] != null) {
        for (var invitation in groupInvitations['received_invitations']) {
          if (invitation != null && 
              invitation['invitation_id'] != null && 
              invitation['group_name'] != null && 
              invitation['invited_by_username'] != null) {
            newAlerts.add(_createGroupInvitationAlert(invitation, groupProvider, context));
          }
        }
      }

      _alerts = newAlerts;
      _updateCategoryCounts();
      
    } catch (e) {
      _logger.severe('Error fetching alerts: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark alert as read (only for static alerts)
  Future<void> markAsRead(BuildContext context, AlertItem alert) async {
    // Skip if alert requires response - those are handled by their respective services
    if (alert.requiresResponse) return;

    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.post(
        Uri.parse('$baseUrl/alerts/mark-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alert_id': alert.id}),
      );

      if (response.statusCode == 200) {
        await fetchAlerts(context); // Refresh alerts and counts
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return markAsRead(context, alert);
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to mark alert as read. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error marking alert as read: $e');
    }
  }

  // Mark all alerts in a category as read
  Future<void> markCategoryAsRead(BuildContext context, AlertCategory category) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.post(
        Uri.parse('$baseUrl/alerts/mark-category-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'category': category.name}),
      );

      if (response.statusCode == 200) {
        await fetchAlerts(context); // Refresh alerts and counts
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return markCategoryAsRead(context, category);
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to mark category as read. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error marking category as read: $e');
    }
  }

  // Mark all static alerts as read
  Future<void> markAllAsRead(BuildContext context) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.post(
        Uri.parse('$baseUrl/alerts/mark-all-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchAlerts(context); // Refresh alerts and counts
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return markAllAsRead(context);
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to mark all alerts as read. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error marking all alerts as read: $e');
    }
  }

  // Clear alerts (e.g., on logout)
  void clear() {
    _alerts = [];
    _categoryCounts = [];
    _processingAlerts.clear();
    notifyListeners();
  }
}
