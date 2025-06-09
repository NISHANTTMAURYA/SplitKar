import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skapp/pages/friends/friends_service.dart';
import 'package:skapp/services/notification_service.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsService _service = FriendsService();
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>>? _potentialFriends;
  String? _error;
  bool _isLoading = false;
  final Set<String> _pendingRequests = {};

  // Getters
  List<Map<String, dynamic>> get potentialFriends => _potentialFriends ?? [];
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool isPending(String profileCode) => _pendingRequests.contains(profileCode);

  // Load potential friends
  Future<void> loadPotentialFriends() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final users = await _service.listOtherUsers();
      _potentialFriends = users;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final index = _potentialFriends?.indexWhere(
        (u) => u['profile_code'] == profileCode
      );
      if (index != null && index != -1) {
        _potentialFriends![index]['friend_request_status'] = 'sent';
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
    if (query.isEmpty) return _potentialFriends!;
    
    final searchQuery = query.toLowerCase();

    return _potentialFriends!.where((user) {
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
    _potentialFriends = null;
    _error = null;
    _isLoading = false;
    _pendingRequests.clear();
    notifyListeners();
  }
} 