import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final _logger = Logger('AuthService');
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _lastValidatedKey = 'last_validated';

  // Use the dynamic base URL
  static String get _baseUrl => AppConfig.baseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    serverClientId: '7120580451-cmn9dcuv9eo0la2path3u1uppeegh37f.apps.googleusercontent.com',
    // clientId: '7120580451-3trd2pl5rapsbfbcqt99cn68o2un4e9v.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Helper to parse backend errors
  String _parseBackendError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        // Check if the error is a single message wrapped in {'error': '...'}
        if (data.containsKey('error') && data['error'] is String) {
          return data['error'];
        }
        // Check for serializer validation errors (a map of field errors)
        else if (data.isNotEmpty) {
          // Concatenate all error messages
          String messages = data.entries.map((entry) {
            String field = entry.key;
            dynamic errorList = entry.value;
            if (errorList is List) {
              return "$field: ${errorList.join(', ')}";
            } else {
              return "$field: $errorList";
            }
          }).join('; ');
          return messages.isNotEmpty ? messages : 'Unknown validation error';
        }
      } else if (data is String) {
        return data; // Handle plain string errors if any
      }
    } catch (e) {
      _logger.severe('Error parsing backend error response: $e');
    }
    return 'An unexpected error occurred';
  }

  // Manual Login
  Future<Map<String, dynamic>?> loginWithEmailOrUsername(String usernameOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail,
          'password': password,
          'profile_picture_url': 'https://lh3.googleusercontent.com/a/default-user=s999', // Default high-res profile picture
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        final errorMessage = _parseBackendError(response);
        throw errorMessage;
      }
    } catch (e) {
      _logger.severe('Error during login: $e');
      rethrow; // Rethrow to be caught by the UI layer
    }
  }

  // Manual Registration
  Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
          'first_name': firstName,
          'last_name': lastName,
          'profile_picture_url': 'https://lh3.googleusercontent.com/a/default-user=s999', // Default high-res profile picture
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        final errorMessage = _parseBackendError(response);
        throw errorMessage; // Throw the specific error message
      }
    } catch (e) {
      _logger.severe('Error during registration: $e');
      rethrow; // Rethrow to be caught by the UI layer
    }
  }

  // Google Sign In
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _logger.info('Starting Google Sign-In');
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      _logger.info('Account: $account');
      if (account == null) {
        _logger.warning('Google Sign In was canceled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      _logger.info('Google Auth: $googleAuth');
      final String? idToken = googleAuth.idToken;
      _logger.info('ID Token length: ${idToken?.length}');
      
      if (idToken == null) {
        _logger.severe('Failed to get ID token from Google Sign In');
        return null;
      }

      // Get the user's photo URL and convert to high resolution
      String? photoUrl = account.photoUrl;
      if (photoUrl != null) {
        // Convert to high resolution URL
        photoUrl = photoUrl.split('=')[0] + '=s999';
        _logger.info('Using high-res profile picture URL: $photoUrl');
      } else {
        _logger.info('No profile picture URL available from Google account');
      }

      _logger.info('Making API call to: $_baseUrl/auth/google/');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'profile_picture_url': photoUrl,
        }),
      );
      _logger.info('HTTP Response Status: ${response.statusCode}');
      _logger.info('HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Successfully decoded response data');
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        // Google sign-in specific error handling might differ slightly
        final errorMessage = _parseBackendError(response);
        _logger.severe('Google Sign-In failed: $errorMessage');
        // Depending on the specific error format, you might return null
        // or throw a specific exception. For now, returning null as before
        // for Google Sign-In API errors.
        return null; // Or throw errorMessage; if you want consistent error handling
      }
    } on PlatformException catch (e) {
      _logger.severe('Platform Exception during Google sign in: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed') {
        _logger.warning('Make sure you have configured the SHA-1 fingerprint in Google Cloud Console');
      }
      rethrow;
    } catch (error) {
      _logger.severe('Error during Google sign in: $error');
      rethrow;
    }
  }

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    // First check if we're online
    final isOnline = await this.isOnline();
    _logger.info('Token validation - Online status: $isOnline');

    if (isOnline) {
      // When online, validate token with backend
      final isValid = await _validateTokenOnline(token);
      if (!isValid) {
        // If validation fails, just logout immediately
        _logger.info('Token validation failed - logging out');
        await signOut();
        return false;
      }
      return true;
    } else {
      // When offline, only check if token exists and isn't expired
      final expiry = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiry != null) {
        final expiryDate = DateTime.parse(expiry);
        final isValid = DateTime.now().isBefore(expiryDate);
        _logger.info('Offline token check - Valid: $isValid');
        return isValid;
      }
      return false;
    }
  }

  Future<bool> _validateTokenOnline(String token) async {
    try {
      _logger.info('Validating token with backend...');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/validate/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      ).timeout(Duration(seconds: 5));

      _logger.info('Token validation response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Update last validated timestamp
        await _secureStorage.write(
          key: _lastValidatedKey,
          value: DateTime.now().toIso8601String(),
        );
        _logger.info('Token validated successfully with backend');
        return true;
      }
      
      // Any non-200 response means we should logout
      _logger.warning('Token validation failed with status: ${response.statusCode}');
      await signOut();
      return false;
    } catch (e) {
      _logger.warning('Token validation failed: $e');
      await signOut();
      return false;
    }
  }

  // Force token validation regardless of cache
  Future<bool> forceTokenValidation() async {
    final token = await getToken();
    if (token == null) return false;

    final isOnline = await this.isOnline();
    if (!isOnline) {
      _logger.info('Cannot force validate - device is offline');
      return false;
    }

    return await _validateTokenOnline(token);
  }

  Future<bool> handleTokenRefresh() async {
    if (!await isOnline()) return false;
    
    try {
      final newToken = await refreshToken();
      if (newToken != null) {
        // Update token expiry to match backend (30 minutes for JWT)
        final expiry = DateTime.now().add(Duration(minutes: 30));
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiry.toIso8601String(),
        );
        return true;
      }
      // If refresh failed and returned null, we should sign out
      await signOut();
      return false;
    } catch (e) {
      _logger.severe('Token refresh failed: $e');
      return false;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    
    // Set token expiry to match backend (30 minutes for JWT)
    final expiry = DateTime.now().add(Duration(minutes: 30));
    await _secureStorage.write(
      key: _tokenExpiryKey,
      value: expiry.toIso8601String(),
    );
    
    // Set last validated timestamp
    await _secureStorage.write(
      key: _lastValidatedKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _lastValidatedKey);
    } catch (error) {
      _logger.severe('Error during sign out: $error');
    }
  }

  Future<String?> refreshToken() async {
    try {
      // First check if we're online
      if (!await isOnline()) {
        _logger.info('Offline mode - skipping token refresh');
        return await getToken();  // Return existing token
      }

      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _logger.warning('No refresh token available');
        await signOut(); // Clear all tokens if refresh token is missing
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        await _secureStorage.write(key: _tokenKey, value: newAccessToken);
        
        // Update token expiry
        final expiry = DateTime.now().add(Duration(minutes: 30));
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiry.toIso8601String(),
        );
        
        return newAccessToken;
      } else {
        // Any non-200 response means we should logout
        _logger.warning('Token refresh failed with status: ${response.statusCode}');
        await signOut();
        return null;
      }
    } catch (e) {
      _logger.warning('Error refreshing token: $e');
      await signOut();
      return null;
    }
  }
} 