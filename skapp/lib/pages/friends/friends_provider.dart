import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skapp/pages/friends/friends_service.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/components/alert_sheet.dart';
import 'package:provider/provider.dart';
import 'package:skapp/pages/friends/freinds.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsService _service = FriendsService();
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>> _potentialFriends = [];
  String? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final Set<String> _pendingRequests = {};

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  // Getters
  List<Map<String, dynamic>> get potentialFriends => _potentialFriends;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool isPending(String profileCode) => _pendingRequests.contains(profileCode);

  // Load initial potential friends
  Future<void> loadPotentialFriends() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      notifyListeners();

      final result = await _service.listOtherUsers(
        page: _currentPage,
        searchQuery: _searchQuery,
      );
      
      _potentialFriends = List<Map<String, dynamic>>.from(result['users']);
      _updatePaginationState(result['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more users (for infinite scroll)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final result = await _service.listOtherUsers(
        page: _currentPage + 1,
        searchQuery: _searchQuery,
      );
      
      final newUsers = List<Map<String, dynamic>>.from(result['users']);
      _potentialFriends.addAll(newUsers);
      _updatePaginationState(result['pagination']);
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

  // Search users
  Future<void> searchUsers(String query) async {
    if (_searchQuery == query) return;
    
    _searchQuery = query;
    await loadPotentialFriends(); // This will reset to page 1 with the new search
  }

  // Send friend request
  Future<void> sendFriendRequest(BuildContext context, Map<String, dynamic> user) async {
    final profileCode = user['profile_code'] as String;
    final username = user['username'] as String;
    if (_pendingRequests.contains(profileCode)) return;

    try {
      _pendingRequests.add(profileCode);
      notifyListeners();

      final result = await _service.sendFriendRequest(profileCode);
      
      // Update the user's status in the list
      final index = _potentialFriends.indexWhere(
        (u) => u['profile_code'] == profileCode
      );
      if (index != -1) {
        _potentialFriends[index]['friend_request_status'] = 'sent';
      }

      // Show success notification
      _notificationService.showAppNotification(
        context,
        title: 'Friend Request Sent',
        message: 'Friend request sent to $username',
        icon: Icons.person_add,
      );
    } finally {
      _pendingRequests.remove(profileCode);
      notifyListeners();
    }
  }

  // Filter users
  List<Map<String, dynamic>> filterUsers(String query) {
    if (_potentialFriends == null) return [];
    if (query.isEmpty) return _potentialFriends;
    
    final searchQuery = query.toLowerCase();

    return _potentialFriends.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      final profileCode = user['profile_code']?.toString().toLowerCase() ?? '';

      // If searching with @, prioritize profile code matches
      if (searchQuery.contains('@')) {
        // Split the profile code into parts (before and after @)
        final parts = profileCode.split('@');
        final searchParts = searchQuery.split('@');
        
        // Match either part of the profile code
        if (searchParts.length > 1) {
          // If search has @, match the parts accordingly
          return (parts[0].contains(searchParts[0].trim()) && 
                 (searchParts[1].isEmpty || parts[1].contains(searchParts[1].trim())));
        } else {
          // If just @ is typed, show all results
          return true;
        }
      }

      // For non-@ searches, check both username and full profile code
      return username.contains(searchQuery) || 
             profileCode.contains(searchQuery) ||
             profileCode.replaceAll('@', '').contains(searchQuery); // Also match without @ symbol
    }).toList();
  }

  // Clear state (useful when navigating away)
  void clear() {
    _potentialFriends = [];
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _pendingRequests.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _searchQuery = '';
    notifyListeners();
  }

  // Friend request handling
  Future<void> loadPendingRequests(BuildContext context) async {
    try {
      final result = await _service.getPendingFriendRequests();
      final alertService = Provider.of<AlertService>(context, listen: false);

      // Process received requests
      for (var request in result['received_requests']) {
        final username = request['from_username'];
        final requestId = request['request_id'].toString();

        alertService.addAlert(
          AlertItem(
            title: 'Friend Request',
            subtitle: '$username wants to be your friend',
            icon: Icons.person_add,
            type: 'friend_request_${requestId}', // Add unique identifier
            timestamp: DateTime.parse(request['created_at']),
            actions: [
              AlertAction(
                label: 'Accept',
                onPressed: () => respondToFriendRequest(context, requestId, true),
                color: Colors.green,
              ),
              AlertAction(
                label: 'Decline',
                onPressed: () => respondToFriendRequest(context, requestId, false),
                color: Colors.red,
              ),
            ],
          ),
        );
      }

      // Process sent requests
      for (var request in result['sent_requests']) {
        final username = request['to_username'];
        final requestId = request['request_id'].toString();
        
        alertService.addAlert(
          AlertItem(
            title: 'Pending Friend Request',
            subtitle: 'Waiting for $username to respond',
            icon: Icons.pending_outlined,
            type: 'friend_request_sent_${requestId}', // Add unique identifier
            timestamp: DateTime.parse(request['created_at']),
            actions: [], // No actions for sent requests
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow; // Rethrow to let the AlertService handle the error
    }
  }

  Future<void> respondToFriendRequest(BuildContext context, String requestId, bool accept) async {
    try {
      final result = await _service.respondToFriendRequest(requestId, accept);
      // When accepting a request, from_user is the username of the person who sent the request
      final username = result['from_user'];

      // Show success notification
      _notificationService.showAppNotification(
        context,
        title: accept ? 'Friend Request Accepted' : 'Friend Request Declined',
        message: accept 
          ? 'You are now friends with $username'
          : 'Friend request from $username declined',
        icon: accept ? Icons.person_add : Icons.person_remove,
      );

      if (accept) {
        // Force refresh the friends list cache
        await _service.clearCache();  // Clear the cache first
        await _service.getFriends(forceRefresh: true);  // This will fetch fresh data
        
        // Reload the friends list
        FreindsPage.reloadFriends();
      }

      // Remove the alert for this request
      final alertService = Provider.of<AlertService>(context, listen: false);
      alertService.removeAlertsByType('friend_request_${requestId}');

      // Refresh pending requests to update the alerts
      await loadPendingRequests(context);
      
    } catch (e) {
      _error = e.toString();
      _notificationService.showAppNotification(
        context,
        title: 'Error',
        message: e.toString(),
        icon: Icons.error,
      );
    }
    notifyListeners();
  }
} 