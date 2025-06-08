import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:skapp/main.dart';

class ProfileApi {
  static final _logger = Logger('ProfileApi');
  static const String _photoUrlKey = 'cached_photo_url';
  static const String _emailKey = 'cached_email';
  static const String _nameKey = 'cached_name';
  static const String _usernameKey = 'cached_username';
  static const String _cacheExpiryKey = 'profile_cache_expiry';
  static const Duration _cacheValidity = Duration(minutes: 5);
  static const int _minLoadingTime = 500; // milliseconds

  final AuthService _authService;
  late SharedPreferences _prefs;

  // Profile data
  Map<String, dynamic>? _profileDetails;
  bool _isLoading = true;
  String? _error;

  // Cached profile data
  String? _cachedPhotoUrl;
  String? _cachedEmail;
  String? _cachedName;
  String? _cachedUsername;

  ProfileApi({AuthService? authService})
    : _authService = authService ?? AuthService();

  // Getters
  Map<String, dynamic>? get profileDetails => _profileDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get photoUrl => _cachedPhotoUrl;
  String? get email => _cachedEmail;
  String? get name => _cachedName;
  String? get username => _cachedUsername;

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Load cached data
      _cachedPhotoUrl = _prefs.getString(_photoUrlKey);
      _cachedEmail = _prefs.getString(_emailKey);
      _cachedName = _prefs.getString(_nameKey);
      _cachedUsername = _prefs.getString(_usernameKey);
    } catch (e) {
      _logger.severe('Error initializing preferences: $e');
    }
  }

  Future<void> _cacheProfileData() async {
    try {
      if (_cachedPhotoUrl != null) {
        await _prefs.setString(_photoUrlKey, _cachedPhotoUrl!);
      }
      if (_cachedEmail != null) {
        await _prefs.setString(_emailKey, _cachedEmail!);
      }
      if (_cachedName != null) {
        await _prefs.setString(_nameKey, _cachedName!);
      }
      if (_cachedUsername != null) {
        await _prefs.setString(_usernameKey, _cachedUsername!);
      }
      // Update cache expiry to 5 minutes from now
      await _prefs.setString(
        _cacheExpiryKey,
        DateTime.now().add(_cacheValidity).toIso8601String(),
      );
      _logger.info('Cache expiry set to: ${DateTime.now().add(_cacheValidity).toIso8601String()}');
    } catch (e) {
      _logger.severe('Error caching profile data: $e');
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final cacheExpiry = await _prefs.getString(_cacheExpiryKey);
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

  Future<void> loadAllProfileData(BuildContext context) async {
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    profileNotifier.setLoading(true);
    profileNotifier.setError(null);

    try {
      // First load cached data
      await _initPrefs();
      _logger.info('Loaded cached data:');
      _logger.info('- Name: ${_cachedName != null ? 'Found' : 'Not found'}');
      _logger.info('- Email: ${_cachedEmail != null ? 'Found' : 'Not found'}');
      _logger.info('- Photo URL: ${_cachedPhotoUrl != null ? 'Found' : 'Not found'}');
      _logger.info('- Username: ${_cachedUsername != null ? 'Found' : 'Not found'}');
      
      // Update UI with cached data immediately if available
      if (context.mounted && _cachedName != null) {
        profileNotifier.updateProfile(
          name: _cachedName,
          email: _cachedEmail,
          photoUrl: _cachedPhotoUrl,
          username: _cachedUsername,
        );
      }

      // Check online status
      final isOnline = await _authService.isOnline();
      _logger.info('Profile data loading decision:');
      _logger.info('- Online status: $isOnline');

      if (isOnline) {
        // When online, always make API call in background
        _logger.info('Online - making API call in background');
        await Future.wait([
          Future.delayed(Duration(milliseconds: _minLoadingTime)),
          Future(() async {
            final token = await _authService.getToken();
            _logger.info('Token available: ${token != null}');
            if (token == null) {
              if (_cachedName == null) {
                profileNotifier.setError('No authentication token available');
              }
              return;
            }

            if (context.mounted) {
              await _loadProfileDetails(token, context);
            }
          }),
        ]);
      } else {
        // When offline, use cache if available
        final isCacheValid = await _isCacheValid();
        _logger.info('Offline mode:');
        _logger.info('- Cache valid: $isCacheValid');
        _logger.info('- Has cached data: ${_cachedName != null}');
        
        if (!isCacheValid && _cachedName == null) {
          profileNotifier.setError('No cached data available');
        }
      }
    } catch (e) {
      _logger.severe('Error in loadAllProfileData: $e');
      if (_cachedName == null) {
        profileNotifier.setError('Error loading profile data');
      }
    } finally {
      profileNotifier.setLoading(false);
    }
  }

  Future<void> _loadProfileDetails(String token, BuildContext context) async {
    try {
      _logger.info('Making API call to /profile/');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 10));

      _logger.info('Profile API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _profileDetails = jsonDecode(response.body);
        // Update cached data from profile details
        _cachedPhotoUrl = _profileDetails?['profile_picture_url'];
        _cachedEmail = _profileDetails?['email'];
        _cachedName = '${_profileDetails?['first_name'] ?? ''} ${_profileDetails?['last_name'] ?? ''}'.trim();
        _cachedUsername = _profileDetails?['username'];
        await _cacheProfileData();
        _logger.info('Profile Details loaded successfully');

        if (context.mounted) {
          final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
          profileNotifier.updateProfile(
            name: _cachedName,
            email: _cachedEmail,
            photoUrl: _cachedPhotoUrl,
            username: _cachedUsername,
          );
        }
      } else if (response.statusCode == 401) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 'token_not_valid') {
          if (context.mounted) {
            final success = await _authService.refreshToken() != null;
            if (success) {
              final newToken = await _authService.getToken();
              if (newToken != null && context.mounted) {
                await _loadProfileDetails(newToken, context);
              }
            }
          }
        } else {
          _error = 'Authentication failed';
        }
      } else {
        _error = 'Failed to load profile. Status code: ${response.statusCode}';
        _logger.warning('Failed to load profile. Response body: ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error loading profile details: $e');
      _error = 'Failed to load profile details';
    }
  }

  Future<void> logout(BuildContext context) async {
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    try {
      await _authService.signOut();
      
      _prefs = await SharedPreferences.getInstance();
      
      // Clear all cached data
      await _prefs.remove(_photoUrlKey);
      await _prefs.remove(_emailKey);
      await _prefs.remove(_nameKey);
      await _prefs.remove(_usernameKey);
      await _prefs.remove(_cacheExpiryKey);

      profileNotifier.clearProfile();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _logger.severe('Error during logout: $e');
      profileNotifier.setError('Error during logout');
    }
  }
}
