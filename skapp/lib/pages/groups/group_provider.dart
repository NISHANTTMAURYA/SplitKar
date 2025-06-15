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
import 'package:logging/logging.dart';

class GroupProvider extends ChangeNotifier {
  // TODO: Add caching implementation
  // final Map<String, dynamic> _cache = {};
  // static const int CACHE_TIMEOUT = 300; // 5 minutes

  final GroupsService _service = GroupsService();
  final NotificationService _notificationService = NotificationService();
  static final _logger = Logger('GroupProvider');

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _users = []; // Add users list
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
  List<Map<String, dynamic>> get groups => _groups;
  List<Map<String, dynamic>> get users => _users; // Add users getter
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  Set<String> get selectedUsers => _selectedUsers;
  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;
  bool get isLoadingInvitations => _isLoadingInvitations;
  String? get invitationError => _invitationError;
  GroupsService get service => _service;

  // TODO: Add request cancellation
  bool _isRequestCancelled = false;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // Load initial users
  Future<void> loadUsers() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _service.getAllUsers(
        page: 1,
        searchQuery: _searchQuery,
      );

      _users = List<Map<String, dynamic>>.from(result['users']);
      _updatePaginationState(result['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load initial users
  Future<void> loadGroups({bool forceRefresh = false}) async {
    if (_isLoading) return;

    try {
      _logger.info('=== Loading groups in provider ===');
      _logger.info('Force refresh: $forceRefresh');
      _logger.info('Current groups in state: ${_groups.length} groups');

      _isLoading = true;
      _error = null;
      notifyListeners();

      final groups = await _service.getGroups(forceRefresh: forceRefresh);
      _groups = groups;
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

    try {
      _searchQuery = query;
      _currentPage = 1;
      _error = null;
      notifyListeners();

      final result = await _service.getAllUsers(
        page: 1,
        searchQuery: _searchQuery,
      );

      _users = List<Map<String, dynamic>>.from(result['users']);
      _updatePaginationState(result['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Reset state when sheet is closed
  void resetState() {
    _groups = [];
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
      _groups.addAll(newUsers);

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
  Future<bool> createGroupAndInvite({
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
      _logger.info('Starting batch group creation process...');

      // Set loading state
      _isLoading = true;
      notifyListeners();

      final result = await _service.batchCreateGroup(
        name: name,
        description: description,
        groupType: groupType,
        profileCodes: _selectedUsers.toList(),
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        tripStatus: tripStatus,
        budget: budget,
      );

      _logger.info('Group created successfully: ${result['group']['id']}');

      // Show success notification
      if (context.mounted) {
        _notificationService.showAppNotification(
          context,
          title: 'Group Created',
          message:
              'Group created and invitations sent to ${_selectedUsers.length} members',
          icon: Icons.group_add,
        );
      }

      // Clear selected users and reset state
      _selectedUsers.clear();
      _error = null;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _logger.severe('Error in createGroupAndInvite: $e');
      _error = e.toString();
      _isLoading = false;

      if (context.mounted) {
        _notificationService.showAppNotification(
          context,
          title: 'Error',
          message: e.toString(),
          icon: Icons.error,
        );
      }

      notifyListeners();
      return false;
    }
  }

  // Load pending invitations
  Future<void> loadPendingInvitations(BuildContext context) async {
    try {
      _isLoadingInvitations = true;
      _invitationError = null;
      notifyListeners();

      _logger.info('Loading pending group invitations...');
      final result = await _service.getPendingInvitations();
      _logger.info('Pending group invitations response: $result');

      if (result != null && result['received_invitations'] != null) {
        _pendingInvitations = List<Map<String, dynamic>>.from(
          result['received_invitations'],
        );
        _logger.info('Processed ${_pendingInvitations.length} invitations');
      } else {
        _pendingInvitations = [];
        _logger.warning('No invitations found in response');
      }

      notifyListeners();
    } catch (e) {
      _invitationError = e.toString();
      _logger.severe('Error loading pending group invitations: $e');
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: 'Failed to load group invitations',
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
      final result = await _service.respondToInvitation(invitationId, accept);

      _logger.info('Response from invitation response: $result');

      // Get group name based on response structure
      String? groupName;
      if (accept && result['group'] != null) {
        groupName = result['group']['name'];
      } else if (!accept && result['invitation'] != null) {
        groupName = result['invitation']['group'];
      }

      if (groupName == null) {
        throw 'Invalid response format from server';
      }

      // Remove the invitation from the list
      _pendingInvitations.removeWhere(
        (invitation) => invitation['invitation_id'] == invitationId,
      );

      // Show success notification
      _notificationService.showAppNotification(
        context,
        title: accept ? 'Invitation Accepted' : 'Invitation Declined',
        message: accept
            ? 'You have joined $groupName'
            : 'You have declined the invitation to $groupName',
        icon: accept ? Icons.check_circle : Icons.cancel,
      );

      // If accepted, refresh groups list
      if (accept) {
        await _service.clearCache();
        await loadGroups(forceRefresh: true);
      }

      // Clear any errors
      _error = null;
      _invitationError = null;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _invitationError = e.toString();
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: e.toString(),
        icon: Icons.error,
      );
      notifyListeners();
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

  // Add this method to refresh groups
  Future<void> refreshGroups() async {
    try {
      _logger.info('Refreshing groups list...');
      _isLoading = true;
      notifyListeners();

      await _service.clearCache();
      final groups = await _service.getGroups(forceRefresh: true);
      _logger.info(
        'Groups list refreshed successfully: ${groups.length} groups',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error refreshing groups: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
