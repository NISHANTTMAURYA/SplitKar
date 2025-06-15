import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsService {
  static final _logger = Logger('FriendsService');
  static const String _friendsCacheKeyPrefix = 'cached_friends_';
  static const String _friendsCacheExpiryKeyPrefix = 'friends_cache_expiry_';
  static const Duration _cacheValidity = Duration(minutes: 5);

  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  String get url => '$baseUrl/friends/list/';
  final _authService = AuthService();
  late SharedPreferences _prefs;

  List<Map<String, dynamic>>? _cachedFriends;

  // Helper method to get user-specific cache keys
  Future<Map<String, String>> _getCacheKeys() async {
    final userId = await _authService.getUserId();
    return {
      'friends': '${_friendsCacheKeyPrefix}${userId ?? ""}',
      'expiry': '${_friendsCacheExpiryKeyPrefix}${userId ?? ""}'
    };
  }

  void dispose() {
    client.close();
    _logger.info('FriendsService http client closed.');
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final cacheKeys = await _getCacheKeys();
      
      // Load cached friends
      final cachedData = _prefs.getString(cacheKeys['friends']!);
      if (cachedData != null) {
        _cachedFriends = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((x) => Map<String, dynamic>.from(x)),
        );
        _logger.info('Loaded ${_cachedFriends?.length} friends from cache');
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

  Future<void> _cacheFriendsData(List<Map<String, dynamic>> friends) async {
    try {
      final cacheKeys = await _getCacheKeys();
      await _prefs.setString(cacheKeys['friends']!, jsonEncode(friends));
      await _prefs.setString(
        cacheKeys['expiry']!,
        DateTime.now().add(_cacheValidity).toIso8601String(),
      );
      _logger.info('Cached ${friends.length} friends');
    } catch (e) {
      _logger.severe('Error caching friends data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFriendsFromApi() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from friends API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> friends =
            List<Map<String, dynamic>>.from(
              jsonDecode(
                response.body,
              ).map((x) => Map<String, dynamic>.from(x)),
            );
        _logger.info('Fetched ${friends.length} friends from API');

        // Cache the fresh data
        await _cacheFriendsData(friends);
        return friends;
      } else if (response.statusCode == 401) {
        // Use the improved token refresh handling
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return _fetchFriendsFromApi(); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch friends. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching friends from API: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFriends({
    bool forceRefresh = false,
  }) async {
    try {
      // Initialize preferences and load cached data
      await _initPrefs();

      // Check online status
      final isOnline = await _authService.isOnline();
      _logger.info('Online status: $isOnline');

      if (isOnline) {
        // When online and force refresh is true or no cache exists, fetch fresh data
        if (forceRefresh || _cachedFriends == null) {
          _logger.info(
            'Fetching fresh friends data. Force refresh: $forceRefresh',
          );
          try {
            final freshFriends = await _fetchFriendsFromApi();
            return freshFriends;
          } catch (e) {
            // If API call fails but we have cached data, use it
            if (_cachedFriends != null) {
              _logger.info('API call failed, using cached data');
              return _cachedFriends!;
            }
            rethrow;
          }
        } else {
          // Check if cache is valid
          final isCacheValid = await _isCacheValid();
          if (!isCacheValid) {
            _logger.info('Cache invalid, fetching fresh data');
            final freshFriends = await _fetchFriendsFromApi();
            return freshFriends;
          } else if (_cachedFriends != null) {
            _logger.info('Using valid cached data');
            return _cachedFriends!;
          }
        }
      } else {
        // When offline, use cached data if available
        if (_cachedFriends != null) {
          _logger.info('Offline mode: using cached data');
          return _cachedFriends!;
        }
        throw 'No internet connection and no cached data available';
      }

      // If we get here, we need fresh data
      return _fetchFriendsFromApi();
    } catch (e) {
      _logger.severe('Error in getFriends: $e');
      rethrow;
    }
  }

  // Helper method to clear cache (useful for logout)
  Future<void> clearCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final cacheKeys = await _getCacheKeys();
      await _prefs.remove(cacheKeys['friends']!);
      await _prefs.remove(cacheKeys['expiry']!);
      _cachedFriends = null;
      _logger.info('Friends cache cleared');
    } catch (e) {
      _logger.severe('Error clearing friends cache: $e');
    }
  }

  Future<Map<String, dynamic>> listOtherUsers({
    int page = 1,
    int pageSize = 10, // Smaller page size for testing
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
        '$baseUrl/profile/list-others/',
      ).replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from list-others API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _logger.info(
          'Fetched ${data['users'].length} potential friends from API (Page $page)',
        );
        return data;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return listOtherUsers(
            page: page,
            pageSize: pageSize,
            searchQuery: searchQuery,
          ); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch users. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching other users: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendFriendRequest(String profileCode) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.post(
        Uri.parse('$baseUrl/friend-request/send/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'profile_code': profileCode}),
      );

      _logger.info(
        'Response status code from send friend request API: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info('Successfully sent friend request: $result');
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return sendFriendRequest(profileCode); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ?? 'Failed to send friend request';
      }
    } catch (e) {
      _logger.severe('Error sending friend request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPendingFriendRequests() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.get(
        Uri.parse('$baseUrl/friend-request/pending/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info(
        'Response status code from pending requests API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info('Fetched pending requests: ${result.toString()}');
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getPendingFriendRequests(); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch pending requests. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching pending friend requests: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> respondToFriendRequest(
    String requestId,
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
        Uri.parse('$baseUrl/friend-request/$endpoint/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': int.parse(requestId)}),
      );

      _logger.info(
        'Response status code from friend request $endpoint API: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        _logger.info(
          'Successfully ${accept ? 'accepted' : 'declined'} friend request: $result',
        );
        return result;
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return respondToFriendRequest(
            requestId,
            accept,
          ); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ??
            'Failed to ${accept ? 'accept' : 'decline'} friend request';
      }
    } catch (e) {
      _logger.severe('Error responding to friend request: $e');
      rethrow;
    }
  }
}
