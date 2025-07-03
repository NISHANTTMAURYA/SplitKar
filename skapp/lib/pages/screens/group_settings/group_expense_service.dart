import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupExpenseService {
  static final _logger = Logger('GroupExpenseService');
  static const String _expensesCacheKeyPrefix = 'cached_group_expenses_';
  static const String _expensesCacheExpiryKeyPrefix =
      'group_expenses_cache_expiry_';
  static const Duration _cacheValidity = Duration(minutes: 5);

  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  late SharedPreferences _prefs;

  // Cache management methods similar to FriendsService
  Map<int, List<Map<String, dynamic>>>? _cachedGroupExpenses;

  Future<Map<String, dynamic>> getGroupExpenses(
    int groupId, {
    int page = 1,
    int pageSize = 5,
    String? searchQuery,
    String searchMode = 'normal',
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      // Build query parameters
      final queryParams = {
        'group_id': groupId.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'search_mode': searchMode,
      };

      // Add search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final uri = Uri.parse(
        '${baseUrl}/expenses/group-expenses/',
      ).replace(queryParameters: queryParams);

      _logger.info('Fetching expenses with params: $queryParams');

      final response = await client.get(
        uri,
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
        _logger.info('Got expenses response: $responseData');

        // Cache first page results if no search query
        if (page == 1 && searchQuery == null) {
          _cachedGroupExpenses?[groupId] = List<Map<String, dynamic>>.from(
            responseData['expenses'],
          );
        }

        return responseData;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getGroupExpenses(
            groupId,
            page: page,
            pageSize: pageSize,
            searchQuery: searchQuery,
            searchMode: searchMode,
          );
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
    int? categoryId,
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
        if (categoryId != null) 'category_id': categoryId,
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
            categoryId: categoryId,
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

  Future<Map<String, dynamic>> editGroupExpense({
    required String expenseId,
    required int groupId,
    required String description,
    required double amount,
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

      final body = {
        'expense_id': expenseId,
        'description': description.trim(),
        'total_amount': amount.toStringAsFixed(2),
      };

      _logger.info('Sending edit expense request with body: $body');

      final response = await client.put(
        Uri.parse('${baseUrl}/expenses/edit/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.info('Edit expense response status: ${response.statusCode}');
      _logger.info('Edit expense response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        if (responseData == null) {
          throw 'Invalid response from server';
        }
        return responseData;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return editGroupExpense(
            expenseId: expenseId,
            groupId: groupId,
            description: description,
            amount: amount,
          );
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error editing group expense: $e');
      rethrow;
    }
  }

  Future<void> deleteGroupExpense({required String expenseId}) async {
    print(
      '[SERVICE DEBUG] deleteGroupExpense called with expenseId=$expenseId',
    );
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.delete(
        Uri.parse('${baseUrl}/expenses/delete-expense/?expense_id=$expenseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
        '[SERVICE DEBUG] API response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return deleteGroupExpense(expenseId: expenseId);
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error deleting group expense: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.get(
        Uri.parse('${baseUrl}/expenses/categories/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return getExpenseCategories();
        }
        throw 'Session expired. Please log in again.';
      } else {
        final error = _parseErrorResponse(response);
        throw error;
      }
    } catch (e) {
      _logger.severe('Error fetching expense categories: $e');
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
