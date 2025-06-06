import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:skapp/config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

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
      print('Error parsing backend error response: $e');
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
      print('Error during login: $e');
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
      print('Error during registration: $e');
      rethrow; // Rethrow to be caught by the UI layer
    }
  }

  // Google Sign In
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In');
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      print('Account: $account');
      if (account == null) {
        print('Google Sign In was canceled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      print('Google Auth: $googleAuth');
      final String? idToken = googleAuth.idToken;
      print('ID Token length: ${idToken?.length}');
      
      if (idToken == null) {
        print('Failed to get ID token from Google Sign In');
        return null;
      }

      print('Making API call to: $_baseUrl/auth/google/');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      print('HTTP Response Status: ${response.statusCode}');
      print('HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Successfully decoded response data');
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        // Google sign-in specific error handling might differ slightly
        final errorMessage = _parseBackendError(response);
        print('Google Sign-In failed: $errorMessage');
        // Depending on the specific error format, you might return null
        // or throw a specific exception. For now, returning null as before
        // for Google Sign-In API errors.
        return null; // Or throw errorMessage; if you want consistent error handling
      }
    } on PlatformException catch (e) {
      print('Platform Exception during Google sign in: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed') {
        print('Make sure you have configured the SHA-1 fingerprint in Google Cloud Console');
      }
      rethrow;
    } catch (error) {
      print('Error during Google sign in: $error');
      rethrow;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      // Validate token with backend
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (error) {
      print('Error during sign out: $error');
    }
  }
} 