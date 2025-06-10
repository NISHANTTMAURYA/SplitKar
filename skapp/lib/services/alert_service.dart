import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:skapp/config.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:skapp/components/alert_sheet.dart';

class AlertService extends ChangeNotifier {
  static final _logger = Logger('AlertService');
  final String baseUrl = AppConfig.baseUrl;
  final _authService = AuthService();
  var client = http.Client();

  List<AlertItem> _alerts = [];
  Set<String> _readAlerts = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<AlertItem> get alerts => _alerts.where((alert) {
    // For static alerts (no response needed), only show unread ones
    if (!alert.requiresResponse) {
      return !_readAlerts.contains(_getAlertId(alert));
    }
    // For response-required alerts, show all (they'll be removed after response)
    return true;
  }).toList();
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get totalCount => _alerts
      .where((alert) => !_readAlerts.contains(_getAlertId(alert)))
      .length;

  // Show alert sheet
  void showAlertSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return AlertSheet(
              alerts: _alerts,
              onClose: () {
                markAllAsRead();
              },
            );
          },
        );
      },
    );
  }

  // Remove alerts by type
  void removeAlertsByType(String type) {
    _alerts.removeWhere((alert) => alert.type == type);
    notifyListeners();
  }

  // Initialize alerts and read status
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Fetch read status from API
      await _fetchReadStatus();

      _isInitialized = true;
    } catch (e) {
      _logger.severe('Error initializing alerts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch read status from API
  Future<void> _fetchReadStatus() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        _logger.warning('No authentication token available');
        throw 'Session expired. Please log in again.';
      }

      final response = await client.get(
        Uri.parse('$baseUrl/alerts/read-status/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _readAlerts = Set<String>.from(data['read_alerts']);
        notifyListeners();
      } else if (response.statusCode == 401) {
        _logger.info('Token expired, attempting refresh...');
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return _fetchReadStatus(); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to fetch read status. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error fetching read status: $e');
      rethrow;
    }
  }

  // Mark alert as read
  Future<void> markAsRead(AlertItem alert) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.post(
        Uri.parse('$baseUrl/alerts/mark-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alert_type': _getAlertId(alert)}),
      );

      if (response.statusCode == 200) {
        _readAlerts.add(_getAlertId(alert));
        // Remove the alert if it's a static alert (no response needed)
        if (!alert.requiresResponse) {
          _alerts.removeWhere((a) => _getAlertId(a) == _getAlertId(alert));
        }
        notifyListeners();
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return markAsRead(alert); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to mark alert as read. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error marking alert as read: $e');
      rethrow;
    }
  }

  // Mark all alerts as read
  Future<void> markAllAsRead() async {
    final unreadAlerts = alerts
        .where((alert) => !isRead(alert))
        .map((alert) => _getAlertId(alert))
        .toList();

    if (unreadAlerts.isEmpty) return;

    try {
      String? token = await _authService.getToken();
      if (token == null) throw 'Session expired. Please log in again.';

      final response = await client.post(
        Uri.parse('$baseUrl/alerts/mark-all-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alert_types': unreadAlerts}),
      );

      if (response.statusCode == 200) {
        _readAlerts.addAll(unreadAlerts);
        notifyListeners();
      } else if (response.statusCode == 401) {
        final refreshSuccess = await _authService.handleTokenRefresh();
        if (refreshSuccess) {
          return markAllAsRead(); // Retry with new token
        }
        throw 'Session expired. Please log in again.';
      } else {
        throw 'Failed to mark all alerts as read. Status: ${response.statusCode}';
      }
    } catch (e) {
      _logger.severe('Error marking all alerts as read: $e');
      rethrow;
    }
  }

  // Add alert with read status check
  void addAlert(AlertItem alert) {
    final existingIndex = _alerts.indexWhere((a) => a.type == alert.type);
    if (existingIndex != -1) {
      _alerts[existingIndex] = alert;
    } else {
      _alerts.insert(0, alert);
    }
    notifyListeners();
  }

  // Check if alert is read
  bool isRead(AlertItem alert) => _readAlerts.contains(_getAlertId(alert));

  String _getAlertId(AlertItem alert) => alert.type;

  // Clear alerts (e.g., on logout)
  void clear() {
    _alerts.clear();
    _readAlerts.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
