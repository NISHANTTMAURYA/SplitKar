import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skapp/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileApi {
  static const String _photoUrlKey = 'cached_photo_url';
  static const String _emailKey = 'cached_email';
  static const String _nameKey = 'cached_name';
  static const int _minLoadingTime = 1; // seconds

  final AuthService _authService;
  final GoogleSignIn _googleSignIn;
  late SharedPreferences _prefs;
  
  // Profile data
  GoogleSignInAccount? _account;
  Map<String, dynamic>? _profileDetails;
  bool _isLoading = true;
  String? _error;
  
  // Cached profile data
  String? _cachedPhotoUrl;
  String? _cachedEmail;
  String? _cachedName;

  ProfileApi({
    AuthService? authService,
    GoogleSignIn? googleSignIn,
  }) : _authService = authService ?? AuthService(),
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Getters
  GoogleSignInAccount? get account => _account;
  Map<String, dynamic>? get profileDetails => _profileDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get photoUrl => _cachedPhotoUrl;
  String? get email => _cachedEmail;
  String? get name => _cachedName;

  String _getHighResPhotoUrl(String? photoUrl) {
    if (photoUrl == null) return '';
    // Remove any existing size parameters and get base URL
    final baseUrl = photoUrl.split('=')[0];
    // Add size parameter for high resolution (500x500)
    return '$baseUrl=s500';
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Load cached data
      _cachedPhotoUrl = _prefs.getString(_photoUrlKey);
      _cachedEmail = _prefs.getString(_emailKey);
      _cachedName = _prefs.getString(_nameKey);
    } catch (e) {
      print('Error initializing preferences: $e');
      // Continue without cached data
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
    } catch (e) {
      print('Error caching profile data: $e');
      // Continue without caching
    }
  }

  Future<void> _loadGoogleAccount() async {
    try {
      _account = await _googleSignIn.signInSilently();
      if (_account != null) {
        _cachedPhotoUrl = _getHighResPhotoUrl(_account!.photoUrl);
        _cachedEmail = _account!.email;
        _cachedName = _account!.displayName;
        await _cacheProfileData();
      }
    } catch (e) {
      print('Error loading Google account: $e');
      _error = 'Failed to load Google account';
    }
  }

  Future<bool> _handleTokenExpiration(BuildContext context) async {
    try {
      // Try to refresh the token
      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        return true;
      }
      
      // If refresh fails, logout and redirect to login
      await logout(context);
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      await logout(context);
      return false;
    }
  }

  Future<void> _loadProfileDetails(String token, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _profileDetails = jsonDecode(response.body);
        print('Profile Details: $_profileDetails');
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        final responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 'token_not_valid') {
          final success = await _handleTokenExpiration(context);
          if (success) {
            // Retry with new token
            final newToken = await _authService.getToken();
            if (newToken != null) {
              await _loadProfileDetails(newToken, context);
            }
          }
        } else {
          _error = 'Authentication failed';
        }
      } else {
        _error = 'Failed to load profile. Status code: ${response.statusCode}';
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error loading profile details: $e');
      _error = 'Failed to load profile details';
    }
  }

  Future<void> loadAllProfileData(BuildContext context) async {
    _isLoading = true;
    _error = null;

    try {
      // Initialize shared preferences
      await _initPrefs();
      
      // Start both the delay and data loading in parallel
      await Future.wait([
        // Minimum loading time
        Future.delayed(Duration(seconds: _minLoadingTime)),
        // Actual data loading
        Future(() async {
          // First load Google account data
          await _loadGoogleAccount();
          
          // Then load profile details from API
          final token = await _authService.getToken();
          if (token == null) {
            _error = 'No authentication token available';
            return;
          }

          await _loadProfileDetails(token, context);
        }),
      ]);
    } catch (e) {
      print('Error in loadAllProfileData: $e');
      _error = 'Error loading profile data';
    } finally {
      _isLoading = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authService.signOut();
      // Clear cached data
      await _prefs.remove(_photoUrlKey);
      await _prefs.remove(_emailKey);
      await _prefs.remove(_nameKey);
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      _error = 'Error during logout';
    }
  }
}