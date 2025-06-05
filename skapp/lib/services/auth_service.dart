import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:skapp/config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  // Use the dynamic base URL
  static String get _baseUrl => AppConfig.baseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    serverClientId: '7120580451-cmn9dcuv9eo0la2path3u1uppeegh37f.apps.googleusercontent.com',
    // clientId: '7120580451-3trd2pl5rapsbfbcqt99cn68o2un4e9v.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
      print('ID Token: $idToken');
      
      if (idToken == null) {
        print('Failed to get ID token from Google Sign In');
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      print('HTTP Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        await _saveToken(data['access']);
        return data;
      } else {
        print('Login failed: ${response.body}');
        return null;
      }
    } on PlatformException catch (e) {
      print('Platform Exception during Google sign in: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed') {
        print('Make sure you have configured the SHA-1 fingerprint in Google Cloud Console');
      }
      return null;
    } catch (error) {
      print('Error during Google sign in: $error');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
    } catch (error) {
      print('Error during sign out: $error');
    }
  }
} 