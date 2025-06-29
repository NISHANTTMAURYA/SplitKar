import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupExpenseService {
  static final _logger = Logger('GroupExpenseService');
  static const String _expensesCacheKeyPrefix = 'cached_group_expenses_';
  static const String _expensesCacheExpiryKeyPrefix = 'group_expenses_cache_expiry_';
  static const Duration _cacheValidity = Duration(minutes: 5);

  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  late SharedPreferences _prefs;

  // Cache management methods similar to FriendsService
  Map<int, List<Map<String, dynamic>>>? _cachedGroupExpenses;

  Future<Map<String, dynamic>> getGroupExpenses(int groupId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.get(
        Uri.parse('${baseUrl}/expenses/group-expenses/?group_id=$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (!responseData.containsKey('expenses')) {
          throw 'Invalid response format: missing expenses key';
        }
        return responseData;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getGroupExpenses(groupId);
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error fetching group expenses: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupBalances(int groupId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.get(
        Uri.parse('${baseUrl}/expenses/group-balances/?group_id=$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (!responseData.containsKey('balances')) {
          throw 'Invalid response format: missing balances key';
        }
        return responseData;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getGroupBalances(groupId);
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error fetching group balances: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addGroupExpense({
    required int groupId,
    required String description,
    required double amount,
    required int payerId,
    required List<int> userIds,
    String? splitType = 'equal',
    List<Map<String, dynamic>>? splits,
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      // Validate inputs
      if (description.trim().isEmpty) {
        throw 'Description cannot be empty';
      }
      if (amount <= 0) {
        throw 'Amount must be greater than 0';
      }
      if (userIds.isEmpty) {
        throw 'At least one user must be selected';
      }

      final body = {
        'description': description.trim(),
        'total_amount': amount.toStringAsFixed(2), // Ensure 2 decimal places
        'payer_id': payerId,
        'user_ids': userIds,
        'group_id': groupId,
        'split_type': splitType,
        if (splits != null) 'splits': splits,
      };

      final response = await client.post(
        Uri.parse('${baseUrl}/expenses/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        if (responseData == null) {
          throw 'Invalid response from server';
        }
        return responseData;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return addGroupExpense(
            groupId: groupId,
            description: description,
            amount: amount,
            payerId: payerId,
            userIds: userIds,
            splitType: splitType,
            splits: splits,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error adding group expense: $e');
      rethrow;
    }
  }

  String _parseErrorResponse(http.Response response) {
    try {
      final error = jsonDecode(response.body);
      if (error is Map<String, dynamic>) {
        if (error.containsKey('error')) return error['error'];
        if (error.containsKey('detail')) return error['detail'];
        if (error.containsKey('message')) return error['message'];
      }
      return 'Request failed with status: ${response.statusCode}';
    } catch (e) {
      return 'Request failed with status: ${response.statusCode}';
    }
  }
}
