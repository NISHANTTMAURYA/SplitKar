/*
 * Alert Service
 * ------------
 * This service is a thin wrapper for backend alert APIs.
 * It handles:
 * 1. Fetching alerts from backend
 * 2. Marking alerts as read
 * 3. Managing alert UI state
 * 
 * Alert Types:
 * 1. Static Alerts:
 *    - Can be marked as read
 *    - Stay in list but marked as read
 * 
 * 2. Responsive Alerts:
 *    - Friend requests, group invites etc.
 *    - Fetched from separate endpoints
 *    - Actions trigger direct API calls
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

  // Getters
  List<AlertItem> get alerts => _alerts;
  List<AlertCategoryCount> get categoryCounts => _categoryCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get total count of alerts requiring attention (unread or requiring response)
  int get totalCount => _categoryCounts.fold(0, (sum, count) => sum + count.unread);

  // Show alert sheet
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
              alerts: _alerts,
              categoryCounts: _categoryCounts,
              onClose: () => fetchAlerts(context), // Refresh on close
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
          onPressed: () async {
            await friendsProvider.respondToFriendRequest(
              context,
              request['request_id'].toString(),
              true,
            );
            // Refresh alerts after action
            fetchAlerts(context);
          },
          color: Colors.green,
        ),
        AlertAction(
          label: 'Decline',
          onPressed: () async {
            await friendsProvider.respondToFriendRequest(
              context,
              request['request_id'].toString(),
              false,
            );
            // Refresh alerts after action
            fetchAlerts(context);
          },
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
          onPressed: () async {
            await groupProvider.handleInvitationResponse(
              context,
              invitation['invitation_id'],
              true,
            );
            // Refresh alerts after action
            fetchAlerts(context);
          },
          color: Colors.green,
        ),
        AlertAction(
          label: 'Decline',
          onPressed: () async {
            await groupProvider.handleInvitationResponse(
              context,
              invitation['invitation_id'],
              false,
            );
            // Refresh alerts after action
            fetchAlerts(context);
          },
          color: Colors.red,
        ),
      ],
      timestamp: DateTime.parse(invitation['created_at'] ?? DateTime.now().toIso8601String()),
      category: AlertCategory.groupInvite,
      requiresResponse: true,
    );
  }

  // Fetch alerts from backend
  Future<void> fetchAlerts(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get providers
      final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      _logger.info('Fetching friend requests and group invitations...');

      // Fetch friend requests and group invitations
      final friendRequests = await friendsProvider.service.getPendingFriendRequests();
      _logger.info('Friend requests response: $friendRequests');
      
      final groupInvitations = await groupProvider.service.getPendingInvitations();
      _logger.info('Group invitations response: $groupInvitations');

      // Convert to AlertItems
      List<AlertItem> newAlerts = [];

      // Add friend requests
      if (friendRequests != null && friendRequests['received_requests'] != null) {
        for (var request in friendRequests['received_requests']) {
          if (request != null && request['request_id'] != null && request['from_username'] != null) {
            _logger.info('Processing friend request: $request');
            newAlerts.add(_createFriendRequestAlert(request, friendsProvider, context));
          }
        }
      }

      // Add group invitations
      if (groupInvitations != null && groupInvitations['received_invitations'] != null) {
        for (var invitation in groupInvitations['received_invitations']) {
          if (invitation != null && 
              invitation['invitation_id'] != null && 
              invitation['group_name'] != null && 
              invitation['invited_by_username'] != null) {
            _logger.info('Processing group invitation: $invitation');
            newAlerts.add(_createGroupInvitationAlert(invitation, groupProvider, context));
          }
        }
      }

      _logger.info('Created ${newAlerts.length} alert items');

      // Update alerts and category counts
      _alerts = newAlerts;
      _categoryCounts = [
        AlertCategoryCount(
          category: AlertCategory.friendRequest,
          total: friendRequests?['received_requests']?.length ?? 0,
          unread: friendRequests?['received_requests']?.length ?? 0,
        ),
        AlertCategoryCount(
          category: AlertCategory.groupInvite,
          total: groupInvitations?['received_invitations']?.length ?? 0,
          unread: groupInvitations?['received_invitations']?.length ?? 0,
        ),
      ];

      _logger.info('Updated alerts and category counts');
      _logger.info('Total alerts: ${_alerts.length}');
      _logger.info('Category counts: $_categoryCounts');

      notifyListeners();
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
    notifyListeners();
  }
}
