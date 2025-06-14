import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupsService {
  static final _logger = Logger('GroupsService');
  static const String _groupsCacheKeyPrefix = 'cached_groups_';
  static const String _groupsCacheExpiryKeyPrefix = 'groups_cache_expiry_';
  static const Duration _cacheValidity = Duration(minutes: 5);

  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  late SharedPreferences _prefs;

  List<Map<String, dynamic>>? _cachedGroups;

  // Helper method to get user-specific cache keys
  Future<Map<String, String>> _getCacheKeys() async {
    final userId = await _authService.getUserId();
    return {
      'groups': '${_groupsCacheKeyPrefix}${userId ?? ""}',
      'expiry': '${_groupsCacheExpiryKeyPrefix}${userId ?? ""}'
    };
  }

  void dispose() {
    client.close();
    _logger.info('GroupsService http client closed.');
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final cacheKeys = await _getCacheKeys();
      
      // Load cached groups
      final cachedData = _prefs.getString(cacheKeys['groups']!);
      if (cachedData != null) {
        _cachedGroups = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((x) => Map<String, dynamic>.from(x)),
        );
        _logger.info('Loaded ${_cachedGroups?.length} groups from cache');
      }
    } catch (e) {
      _logger.severe('Error initializing preferences: $e');
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final cacheKeys = await _getCacheKeys();
      final cacheExpiry = _prefs.getString(cacheKeys['expiry']!);
      _logger.info('Cache expiry from storage: $cacheExpiry');

      if (cacheExpiry == null) {
        _logger.info('No cache expiry found - cache is invalid');
        return false;
      }

      final expiryDate = DateTime.parse(cacheExpiry);
      final now = DateTime.now();
      final isValid = now.isBefore(expiryDate);

      _logger.info('Cache validation:');
      _logger.info('- Current time: $now');
      _logger.info('- Expiry time: $expiryDate');
      _logger.info('- Is valid: $isValid');

      return isValid;
    } catch (e) {
      _logger.warning('Error checking cache validity: $e');
      return false;
    }
  }

  Future<void> _cacheGroupsData(List<Map<String, dynamic>> groups) async {
    try {
      final cacheKeys = await _getCacheKeys();
      await _prefs.setString(cacheKeys['groups']!, jsonEncode(groups));
      await _prefs.setString(
        cacheKeys['expiry']!,
        DateTime.now().add(_cacheValidity).toIso8601String(),
      );
      _logger.info('Cached ${groups.length} groups');
    } catch (e) {
      _logger.severe('Error caching groups data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGroupsFromApi() async {
    try {
      _logger.info('=== Fetching groups from API ===');
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }
      
      _logger.info('Making request to: $baseUrl/group/list/');

      final response = await client.get(
        Uri.parse('$baseUrl/group/list/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from groups API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        _logger.info('Raw API response: ${response.body}');
        
        final List<Map<String, dynamic>> groups =
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body).map((x) => Map<String, dynamic>.from(x)),
            );
        _logger.info('Fetched ${groups.length} groups from API');
        _logger.info('Parsed groups data: $groups');

        // Cache the fresh data
        await _cacheGroupsData(groups);
        return groups;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return _fetchGroupsFromApi(); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch groups. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching groups from API: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGroups({
    bool forceRefresh = false,
  }) async {
    try {
      _logger.info('=== Starting getGroups ===');
      _logger.info('Force refresh: $forceRefresh');
      
      // Initialize preferences and load cached data
      await _initPrefs();

      // Check online status
      final isOnline = await _authService.isOnline();
      _logger.info('Online status: $isOnline');
      
      if (_cachedGroups != null) {
        _logger.info('Current cached groups: ${_cachedGroups!.length} groups');
        _logger.info('Cached groups data: $_cachedGroups');
      } else {
        _logger.info('No cached groups data available');
      }

      if (isOnline) {
        // When online and force refresh is true or no cache exists, fetch fresh data
        if (forceRefresh || _cachedGroups == null) {
          _logger.info(
            'Fetching fresh groups data. Force refresh: $forceRefresh',
          );
          try {
            final freshGroups = await _fetchGroupsFromApi();
            return freshGroups;
          } catch (e) {
            // If API call fails but we have cached data, use it
            if (_cachedGroups != null) {
              _logger.info('API call failed, using cached data');
              return _cachedGroups!;
            }
            rethrow;
          }
        } else {
          // Check if cache is valid
          final isCacheValid = await _isCacheValid();
          if (!isCacheValid) {
            _logger.info('Cache invalid, fetching fresh data');
            final freshGroups = await _fetchGroupsFromApi();
            return freshGroups;
          } else if (_cachedGroups != null) {
            _logger.info('Using valid cached data');
            return _cachedGroups!;
          }
        }
      } else {
        // When offline, use cached data if available
        if (_cachedGroups != null) {
          _logger.info('Offline mode: using cached data');
          return _cachedGroups!;
        }
        throw 'No internet connection and no cached data available';
      }

      // If we get here, we need fresh data
      return _fetchGroupsFromApi();
    } catch (e) {
      _logger.severe('Error in getGroups: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGroup({
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
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      // Validate trip group fields
      if (groupType == 'trip') {
        if (destination == null || destination.isEmpty) {
          throw 'Destination is required for trip groups';
        }
        if (startDate == null) {
          throw 'Start date is required for trip groups';
        }
        if (endDate == null) {
          throw 'End date is required for trip groups';
        }
        if (tripStatus == null || tripStatus.isEmpty) {
          throw 'Trip status is required for trip groups';
        }
      }

      final body = {
        'name': name,
        'description': description,
        'group_type': groupType,
        if (groupType == 'trip') ...{
          'destination': destination,
          'start_date': startDate?.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'trip_status': tripStatus,
          if (budget != null) 'budget': budget.toString(),
        },
      };

      _logger.info('Creating group with body: $body');

      final response = await client.post(
        Uri.parse('$baseUrl/group/create/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.info(
        'Response status code from create group API: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info('Successfully created group: $result');
        
        // Clear cache and fetch fresh data
        await clearCache();
        await getGroups(forceRefresh: true);
        
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return createGroup(
            name: name,
            description: description,
            groupType: groupType,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            tripStatus: tripStatus,
            budget: budget,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        _logger.severe('Error response from API: ${response.body}');
        throw errorData['error'] ?? 'Failed to create group';
      }
    } catch (e) {
      _logger.severe('Error creating group: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inviteToGroup({
    required int groupId,
    required List<String> profileCodes,
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.post(
        Uri.parse('$baseUrl/group/invite/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'group_id': groupId,
          'profile_codes': profileCodes,
        }),
      );

      _logger.info(
        'Response status code from invite to group API: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info('Successfully sent group invitations: $result');
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return inviteToGroup(
            groupId: groupId,
            profileCodes: profileCodes,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ?? 'Failed to send group invitations';
      }
    } catch (e) {
      _logger.severe('Error sending group invitations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPendingInvitations() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.get(
        Uri.parse('$baseUrl/group/invitation/pending/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from pending invitations API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info('Fetched pending invitations: ${result.toString()}');
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getPendingInvitations();
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch pending invitations. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching pending group invitations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> respondToInvitation(
    int invitationId,
    bool accept,
  ) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final endpoint = accept ? 'accept' : 'decline';
      final response = await client.post(
        Uri.parse('$baseUrl/group/invitation/$endpoint/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'invitation_id': invitationId}),
      );

      _logger.info(
        'Response status code from group invitation $endpoint API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info(
          'Successfully ${accept ? 'accepted' : 'declined'} group invitation: $result',
        );
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return respondToInvitation(invitationId, accept);
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ??
            'Failed to ${accept ? 'accept' : 'decline'} group invitation';
      }
    } catch (e) {
      _logger.severe('Error responding to group invitation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
      };

      final uri = Uri.parse(
        '$baseUrl/profile/list-all/',
      ).replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from list-all API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Ensure the response has the expected format
        if (!data.containsKey('users') || !data.containsKey('pagination')) {
          throw 'Invalid response format from server';
        }

        _logger.info(
          'Fetched ${data['users'].length} users from API (Page $page)',
        );
        return data;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getAllUsers(
            page: page,
            pageSize: pageSize,
            searchQuery: searchQuery,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch users. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching users: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.get(
        Uri.parse('$baseUrl/friends/list/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from friends list API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> friends =
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body).map((x) => Map<String, dynamic>.from(x)),
            );
        _logger.info('Fetched ${friends.length} friends from API');
        return friends;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getFriendsList();
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch friends. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching friends list: $e');
      rethrow;
    }
  }

  // Helper method to clear cache (useful for logout)
  Future<void> clearCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final cacheKeys = await _getCacheKeys();
      await _prefs.remove(cacheKeys['groups']!);
      await _prefs.remove(cacheKeys['expiry']!);
      _cachedGroups = null;
      _logger.info('Groups cache cleared');
    } catch (e) {
      _logger.severe('Error clearing groups cache: $e');
    }
  }

  Future<Map<String, dynamic>> batchCreateGroup({
    required String name,
    required String description,
    required String groupType,
    required List<String> profileCodes,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? tripStatus,
    double? budget,
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw 'Session expired. Please log in again.';
      }

      final body = {
        'name': name,
        'description': description,
        'group_type': groupType,
        'profile_codes': profileCodes,
        if (groupType == 'trip') ...{
          'destination': destination,
          'start_date': startDate?.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'trip_status': tripStatus,
          if (budget != null) 'budget': budget.toString(),
        },
      };

      final response = await client.post(
        Uri.parse('$baseUrl/group/batch-create/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        // Clear cache and fetch fresh data
        await clearCache();
        await getGroups(forceRefresh: true);
        return result;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return batchCreateGroup(
            name: name,
            description: description,
            groupType: groupType,
            profileCodes: profileCodes,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            tripStatus: tripStatus,
            budget: budget,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ?? 'Failed to create group';
      }
    } catch (e) {
      _logger.severe('Error in batch create group: $e');
      rethrow;
    }
  }
}
