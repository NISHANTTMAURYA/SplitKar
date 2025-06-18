import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skapp/config.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:logging/logging.dart';

class GroupSettingsApi {
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  final _client = http.Client();
  static final _logger = Logger('GroupSettingsApi');

  Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw 'Session expired. Please log in again.';
      }

      _logger.info('Fetching group details for group ID: $groupId');
      final response = await _client.get(
        Uri.parse('$baseUrl/group/details/$groupId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.info('Response status code: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getGroupDetails(groupId);
        }
        throw 'Session expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'You are not a member of this group';
      } else if (response.statusCode == 404) {
        throw 'Group not found';
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['error'] ?? 'Failed to fetch group details';
      }
    } catch (e) {
      _logger.severe('Error fetching group details: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
} 