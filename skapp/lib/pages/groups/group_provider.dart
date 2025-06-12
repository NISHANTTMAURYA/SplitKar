/*
 * Friends Provider Optimization Notes
 * --------------------------------
 * 1. State Management:
 *    - Current: Basic ChangeNotifier implementation
 *    - Needed: Better state organization and caching
 *    - Consider: Using a more robust state management solution
 * 
 * 2. API Calls:
 *    - Current: Individual API calls for each operation
 *    - Needed: Batch operations and proper caching
 *    - Consider: Implementing request queuing
 * 
 * 3. Performance:
 *    - Add proper error handling and retry mechanism
 *    - Implement request cancellation
 *    - Add proper loading states
 * 
 * 4. Memory Management:
 *    - Implement proper resource cleanup
 *    - Add memory leak prevention
 *    - Optimize data structures
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skapp/pages/groups/group_service.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/components/alert_sheet.dart';
import 'package:provider/provider.dart';
import 'package:skapp/pages/groups/groups.dart';
import 'package:skapp/main.dart';

class GroupProvider extends ChangeNotifier {
  // TODO: Add caching implementation
  // final Map<String, dynamic> _cache = {};
  // static const int CACHE_TIMEOUT = 300; // 5 minutes

  final GroupsService _service = GroupsService();
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _users = [];
  String? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final Set<String> _selectedUsers = {};

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _isLoadingInvitations = false;
  String? _invitationError;

  // Getters
  List<Map<String, dynamic>> get users => _users;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  Set<String> get selectedUsers => _selectedUsers;
  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;
  bool get isLoadingInvitations => _isLoadingInvitations;
  String? get invitationError => _invitationError;

  // TODO: Add request cancellation
  bool _isRequestCancelled = false;

  // Load initial users
  Future<void> loadUsers() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _users = []; // Clear existing users
      notifyListeners();

      final result = await _service.getAllUsers(
        page: _currentPage,
        searchQuery: _searchQuery,
      );

      // Get all users from the response
      final allUsers = List<Map<String, dynamic>>.from(result['users']);
      
      // Update pagination state
      _updatePaginationState(result['pagination']);
      
      // Store all users
      _users = allUsers;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search users with debounce
  Future<void> searchUsers(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    _currentPage = 1;
    _users = []; // Clear existing users
    _hasMore = true; // Reset pagination
    await loadUsers();
  }

  // Reset state when sheet is closed
  void resetState() {
    _users = [];
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _selectedUsers.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _searchQuery = '';
    _pendingInvitations.clear();
    _invitationError = null;
    notifyListeners();
  }

  // Toggle user selection
  void toggleUserSelection(String profileCode) {
    if (_selectedUsers.contains(profileCode)) {
      _selectedUsers.remove(profileCode);
    } else {
      _selectedUsers.add(profileCode);
    }
    notifyListeners();
  }

  // Load more users (for infinite scroll)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final result = await _service.getAllUsers(
        page: _currentPage + 1,
        searchQuery: _searchQuery,
      );

      // Get new users from the response
      final newUsers = List<Map<String, dynamic>>.from(result['users']);
      
      // Add new users to the existing list
      _users.addAll(newUsers);
      
      // Update pagination state
      _updatePaginationState(result['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Update pagination state
  void _updatePaginationState(Map<String, dynamic> pagination) {
    _currentPage = pagination['page'];
    _totalPages = pagination['total_pages'];
    _hasMore = pagination['has_next'];
  }

  // Create group and invite selected users
  Future<void> createGroupAndInvite({
    required BuildContext context,
    required String name,
    required String description,
    required String groupType,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? tripStatus,
    double? budget,
  }) async {
    try {
      // Create the group first
      final groupResult = await _service.createGroup(
        name: name,
        description: description,
        groupType: groupType,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        tripStatus: tripStatus,
        budget: budget,
      );

      // If there are selected users, invite them
      if (_selectedUsers.isNotEmpty) {
        await _service.inviteToGroup(
          groupId: groupResult['id'],
          profileCodes: _selectedUsers.toList(),
        );

        // Show success notification
        _notificationService.showAppNotification(
          context,
          title: 'Group Created',
          message: 'Group created and invitations sent to ${_selectedUsers.length} members',
          icon: Icons.group_add,
        );

        // Create alert for group creation
        final alertService = Provider.of<AlertService>(context, listen: false);
        alertService.addAlert(
          AlertItem(
            title: 'New Group Created',
            subtitle: 'You created a new group: $name',
            icon: Icons.group,
            type: 'group_created_${groupResult['id']}',
            timestamp: DateTime.now(),
            category: AlertCategory.groupInvite,
            requiresResponse: false,
            actions: [],
          ),
        );
      }

      // Clear selected users and reset state
      _selectedUsers.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: e.toString(),
        icon: Icons.error,
      );
      notifyListeners();
    }
  }

  // Load pending invitations
  Future<void> loadPendingInvitations(BuildContext context) async {
    try {
      _isLoadingInvitations = true;
      _invitationError = null;
      notifyListeners();

      final result = await _service.getPendingInvitations();
      _pendingInvitations = List<Map<String, dynamic>>.from(result['invitations']);

      // Create alerts for new invitations
      final alertService = Provider.of<AlertService>(context, listen: false);
      for (final invitation in _pendingInvitations) {
        final groupName = invitation['group']['name'];
        final invitedBy = invitation['invited_by']['username'];
        
        // Check if alert already exists
        final existingAlert = alertService.alerts.any(
          (alert) => alert.type == 'group_invite_${invitation['id']}'
        );
        
        if (!existingAlert) {
          alertService.addAlert(
            AlertItem(
              title: 'Group Invitation',
              subtitle: '$invitedBy invited you to join $groupName',
              icon: Icons.group_add,
              type: 'group_invite_${invitation['id']}',
              timestamp: DateTime.parse(invitation['created_at']),
              category: AlertCategory.groupInvite,
              requiresResponse: true,
              actions: [
                AlertAction(
                  label: 'Accept',
                  onPressed: () => handleInvitationResponse(
                    context,
                    invitation['id'],
                    true,
                  ),
                  color: Colors.green,
                ),
                AlertAction(
                  label: 'Decline',
                  onPressed: () => handleInvitationResponse(
                    context,
                    invitation['id'],
                    false,
                  ),
                  color: Colors.red,
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _invitationError = e.toString();
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: e.toString(),
        icon: Icons.error,
      );
    } finally {
      _isLoadingInvitations = false;
      notifyListeners();
    }
  }

  // Handle invitation response (accept/decline)
  Future<void> handleInvitationResponse(
    BuildContext context,
    int invitationId,
    bool accept,
  ) async {
    try {
      final result = await _service.respondToInvitation(
        invitationId,
        accept,
      );

      // Remove the invitation from the list
      _pendingInvitations.removeWhere(
        (invitation) => invitation['id'] == invitationId
      );

      // Remove the alert
      final alertService = Provider.of<AlertService>(context, listen: false);
      alertService.removeAlertsByType('group_invite_$invitationId');

      // Show success notification
      _notificationService.showAppNotification(
        context,
        title: accept ? 'Invitation Accepted' : 'Invitation Declined',
        message: accept 
          ? 'You have joined the group'
          : 'You have declined the invitation',
        icon: accept ? Icons.check_circle : Icons.cancel,
      );

      // If accepted, refresh groups list
      if (accept) {
        await _service.clearCache();
        await _service.getGroups(forceRefresh: true);
      }

      notifyListeners();
    } catch (e) {
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: e.toString(),
        icon: Icons.error,
      );
    }
  }

  // TODO: Implement batch operations
  Future<void> batchProcessFriendRequests(List<String> profileCodes) async {
    // Implementation needed
  }

  // TODO: Add proper error recovery
  Future<void> _handleApiError(dynamic error) async {
    // Implementation needed
  }

  Future<void> loadPendingRequests(BuildContext context) async {
    // This method should be moved to FriendsProvider
    throw UnimplementedError('This method should be in FriendsProvider');
  }

  Future<void> respondToFriendRequest(
    BuildContext context,
    String requestId,
    bool accept,
  ) async {
    // This method should be moved to FriendsProvider
    throw UnimplementedError('This method should be in FriendsProvider');
  }
}
