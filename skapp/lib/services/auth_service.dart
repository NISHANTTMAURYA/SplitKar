import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';

// Custom exception classes for better error handling
class AuthException implements Exception {
  final String message;
  final String code;
  
  AuthException(this.message, {this.code = 'unknown'});
  
  @override
  String toString() => message;
}

class NetworkException extends AuthException {
  NetworkException(String message) : super(message, code: 'network_error');
}

class ValidationException extends AuthException {
  ValidationException(String message) : super(message, code: 'validation_error');
}

class AuthService {
  static final _logger = Logger('AuthService');
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _lastValidatedKey = 'last_validated';
  static const String _userIdKey = 'user_id';

  // Use the dynamic base URL
  static String get _baseUrl => AppConfig.baseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    serverClientId: '7120580451-cmn9dcuv9eo0la2path3u1uppeegh37f.apps.googleusercontent.com',
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

  // Helper to handle different types of exceptions
  String _handleException(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection and try again.';
    } else if (error is HttpException) {
      return 'Server communication error. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid response from server. Please try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is PlatformException) {
      // Handle platform-specific errors
      switch (error.code) {
        case 'sign_in_failed':
          return 'Google Sign-In failed. Please try again.';
        case 'network_error':
          return 'Network error occurred. Please check your connection.';
        default:
          return 'An error occurred: ${error.message ?? 'Unknown error'}';
      }
    } else if (error is AuthException) {
      return error.message; // Our custom exceptions already have user-friendly messages
    } else if (error is String) {
      return error; // Backend error messages are already user-friendly
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Manual Login with improved error handling
  Future<Map<String, dynamic>?> loginWithEmailOrUsername(String usernameOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail,
          'password': password,
          'profile_picture_url': 'https://lh3.googleusercontent.com/a/default-user=s999',
        }),
      ).timeout(Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        final errorMessage = _parseBackendError(response);
        throw ValidationException(errorMessage);
      }
    } on TimeoutException catch (e) {
      _logger.severe('Timeout during login: $e');
      throw NetworkException('Request timed out. Please try again.');
    } on SocketException catch (e) {
      _logger.severe('Network error during login: $e');
      throw NetworkException('Unable to connect to server. Please check your internet connection or try again later.');
    } on FormatException catch (e) {
      _logger.severe('Invalid response format during login: $e');
      throw AuthException('Invalid response from server. Please try again.');
    } catch (e) {
      _logger.severe('Error during login: $e');
      if (e is AuthException) {
        rethrow; // Re-throw our custom exceptions
      }
      throw AuthException(_handleException(e));
    }
  }

  // Manual Registration with improved error handling
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
          'profile_picture_url': 'https://lh3.googleusercontent.com/a/default-user=s999',
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        final errorMessage = _parseBackendError(response);
        throw ValidationException(errorMessage);
      }
    } on TimeoutException catch (e) {
      _logger.severe('Timeout during registration: $e');
      throw NetworkException('Request timed out. Please try again.');
    } on SocketException catch (e) {
      _logger.severe('Network error during registration: $e');
      throw NetworkException('Unable to connect to server. Please check your internet connection or try again later');
    } on FormatException catch (e) {
      _logger.severe('Invalid response format during registration: $e');
      throw AuthException('Invalid response from server. Please try again.');
    } catch (e) {
      _logger.severe('Error during registration: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(_handleException(e));
    }
  }

  // Google Sign In with improved error handling
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _logger.info('Starting Google Sign-In');
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      _logger.info('Account: $account');
      
      if (account == null) {
        _logger.warning('Google Sign In was canceled by user');
        return null; // User cancelled - don't throw error
      }

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      _logger.info('Google Auth: $googleAuth');
      final String? idToken = googleAuth.idToken;
      _logger.info('ID Token length: ${idToken?.length}');
      
      if (idToken == null) {
        _logger.severe('Failed to get ID token from Google Sign In');
        throw AuthException('Google Sign-In failed. Please try again.');
      }

      // Get the user's photo URL and convert to high resolution
      String? photoUrl = account.photoUrl;
      if (photoUrl != null) {
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
      ).timeout(Duration(seconds: 10));
      
      _logger.info('HTTP Response Status: ${response.statusCode}');
      _logger.info('HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Successfully decoded response data');
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        final errorMessage = _parseBackendError(response);
        _logger.severe('Google Sign-In failed: $errorMessage');
        throw AuthException('Google Sign-In failed: $errorMessage');
      }
    } on PlatformException catch (e) {
      _logger.severe('Platform Exception during Google sign in: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed') {
        throw AuthException('Google Sign-In failed. Please try again.');
      } else if (e.code == 'network_error') {
        throw NetworkException('Network error during Google Sign-In. Please check your connection.');
      } else {
        throw AuthException('Google Sign-In error: ${e.message ?? 'Unknown error'}');
      }
    } on TimeoutException catch (e) {
      _logger.severe('Timeout during Google sign in: $e');
      throw NetworkException('Request timed out. Please try again.');
    } on SocketException catch (e) {
      _logger.severe('Network error during Google sign in: $e');
      throw NetworkException('Unable to connect to server. Please check your internet connection or try again later.');
    } catch (e) {
      _logger.severe('Error during Google sign in: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(_handleException(e));
    }
  }

  // Rest of your methods remain the same...
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

    final isOnline = await this.isOnline();
    _logger.info('Token validation - Online status: $isOnline');

    if (isOnline) {
      final isValid = await _validateTokenOnline(token);
      if (!isValid) {
        _logger.info('Token validation failed - logging out');
        await signOut();
        return false;
      }
      return true;
    } else {
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
        await _secureStorage.write(
          key: _lastValidatedKey,
          value: DateTime.now().toIso8601String(),
        );
        _logger.info('Token validated successfully with backend');
        return true;
      }
      
      _logger.warning('Token validation failed with status: ${response.statusCode}');
      await signOut();
      return false;
    } catch (e) {
      _logger.warning('Token validation failed: $e');
      await signOut();
      return false;
    }
  }

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
        final expiry = DateTime.now().add(Duration(minutes: 30));
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiry.toIso8601String(),
        );
        return true;
      }
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
    
    final expiry = DateTime.now().add(Duration(minutes: 30));
    await _secureStorage.write(
      key: _tokenExpiryKey,
      value: expiry.toIso8601String(),
    );
    
    await _secureStorage.write(
      key: _lastValidatedKey,
      value: DateTime.now().toIso8601String(),
    );

    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
        );
        final userId = payload['user_id']?.toString();
        if (userId != null) {
          await _secureStorage.write(key: _userIdKey, value: userId);
        }
      }
    } catch (e) {
      _logger.warning('Error caching user ID from token: $e');
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> signOut() async {
    try {
      _logger.info('Starting sign out process...');
      
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _lastValidatedKey);
      await _secureStorage.delete(key: _userIdKey);
      
      await _googleSignIn.signOut();
      _logger.info('Successfully signed out');
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      rethrow;
    }
  }

  Future<String?> refreshToken() async {
    try {
      if (!await isOnline()) {
        _logger.info('Offline mode - skipping token refresh');
        return await getToken();
      }

      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _logger.warning('No refresh token available');
        await signOut();
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
        
        final expiry = DateTime.now().add(Duration(minutes: 30));
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiry.toIso8601String(),
        );
        
        return newAccessToken;
      } else {
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

  Future<String?> getUserId() async {
    try {
      final cachedUserId = await _secureStorage.read(key: _userIdKey);
      if (cachedUserId != null) {
        _logger.info('Using cached user ID');
        return cachedUserId;
      }

      final token = await getToken();
      if (token == null) {
        _logger.warning('No token available to get user ID');
        return null;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.warning('Invalid token format');
        return null;
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final userId = payload['user_id']?.toString();
      if (userId != null) {
        await _secureStorage.write(key: _userIdKey, value: userId);
        _logger.info('Cached user ID from token');
      }

      return userId;
    } catch (e) {
      _logger.severe('Error getting user ID: $e');
      return null;
    }
  }
}