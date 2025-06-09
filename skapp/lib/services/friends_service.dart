import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsService {
  static final _logger = Logger('FriendsService');
  static const String _friendsCacheKey = 'cached_friends';
  static const String _friendsCacheExpiryKey = 'friends_cache_expiry';
  static const Duration _cacheValidity = Duration(minutes: 5);

  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  String get url => '$baseUrl/friends/list/';
  final _authService = AuthService();
  late SharedPreferences _prefs;

  List<Map<String, dynamic>>? _cachedFriends;

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Load cached friends
      final cachedData = _prefs.getString(_friendsCacheKey);
      if (cachedData != null) {
        _cachedFriends = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((x) => Map<String, dynamic>.from(x))
        );
        _logger.info('Loaded ${_cachedFriends?.length} friends from cache');
      }
    } catch (e) {
      _logger.severe('Error initializing preferences: $e');
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final cacheExpiry = _prefs.getString(_friendsCacheExpiryKey);
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
      await _prefs.setString(_friendsCacheKey, jsonEncode(friends));
      await _prefs.setString(
        _friendsCacheExpiryKey,
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

      _logger.info('Response status code from friends API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> friends = List<Map<String, dynamic>>.from(
          jsonDecode(response.body).map((x) => Map<String, dynamic>.from(x))
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

  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      // Initialize preferences and load cached data
      await _initPrefs();

      // Check online status
      final isOnline = await _authService.isOnline();
      _logger.info('Online status: $isOnline');

      if (isOnline) {
        // When online, always fetch fresh data
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
        // When offline, use cached data if available
        if (_cachedFriends != null) {
          _logger.info('Offline mode: using cached data');
          return _cachedFriends!;
        }
        throw 'No internet connection and no cached data available';
      }
    } catch (e) {
      _logger.severe('Error in getFriends: $e');
      rethrow;
    }
  }

  // Helper method to clear cache (useful for logout)
  Future<void> clearCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.remove(_friendsCacheKey);
      await _prefs.remove(_friendsCacheExpiryKey);
      _cachedFriends = null;
      _logger.info('Friends cache cleared');
    } catch (e) {
      _logger.severe('Error clearing friends cache: $e');
    }
  }
}
