import 'package:flutter/material.dart';
import 'package:skapp/components/alert_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlertService extends ChangeNotifier {
  static const String _alertsCacheKey = 'cached_alerts';
  List<AlertItem> _alerts = [];
  bool _isLoading = false;
  final Set<String> _readAlerts = {};

  // Getters
  List<AlertItem> get alerts => _alerts;
  bool get isLoading => _isLoading;
  int get totalCount => _alerts.where((alert) => !_readAlerts.contains(_getAlertId(alert))).length;

  AlertService() {
    _loadFromCache();
  }

  // Show alert sheet
  void showAlertSheet(BuildContext context) {
    AlertSheet.show(
      context,
      alerts: _alerts,
      onClose: () {
        markAllAsRead();
      },
    );
  }

  // Add a new alert
  void addAlert(AlertItem alert) {
    _alerts.insert(0, alert); // Add to the beginning of the list
    _saveToCache();
    notifyListeners();
  }

  // Remove an alert
  void removeAlert(AlertItem alert) {
    _alerts.remove(alert);
    _readAlerts.remove(_getAlertId(alert));
    _saveToCache();
    notifyListeners();
  }

  // Clear all alerts
  void clearAlerts() {
    _alerts.clear();
    _readAlerts.clear();
    _saveToCache();
    notifyListeners();
  }

  // Mark specific alert as read
  void markAsRead(AlertItem alert) {
    _readAlerts.add(_getAlertId(alert));
    _saveToCache();
    notifyListeners();
  }

  // Mark all alerts as read
  void markAllAsRead() {
    for (var alert in _alerts) {
      _readAlerts.add(_getAlertId(alert));
    }
    _saveToCache();
    notifyListeners();
  }

  // Check if an alert is read
  bool isRead(AlertItem alert) {
    return _readAlerts.contains(_getAlertId(alert));
  }

  // Generate a unique ID for an alert
  String _getAlertId(AlertItem alert) {
    return '${alert.type}_${alert.timestamp.millisecondsSinceEpoch}_${alert.title.hashCode}';
  }

  // Save alerts to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsData = _alerts.map((alert) => {
        'title': alert.title,
        'subtitle': alert.subtitle,
        'imageUrl': alert.imageUrl,
        'icon': alert.icon.codePoint,
        'timestamp': alert.timestamp.toIso8601String(),
        'type': alert.type,
      }).toList();

      await prefs.setString(_alertsCacheKey, jsonEncode(alertsData));
      await prefs.setStringList('read_alerts', _readAlerts.toList());
    } catch (e) {
      debugPrint('Error saving alerts to cache: $e');
    }
  }

  // Load alerts from cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsCacheKey);
      final readAlertsList = prefs.getStringList('read_alerts');

      if (alertsJson != null) {
        final alertsData = jsonDecode(alertsJson) as List;
        _alerts = alertsData.map((data) => AlertItem(
          title: data['title'],
          subtitle: data['subtitle'],
          imageUrl: data['imageUrl'],
          icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
          actions: [], // Actions are not cached as they contain callbacks
          timestamp: DateTime.parse(data['timestamp']),
          type: data['type'],
        )).toList();
      }

      if (readAlertsList != null) {
        _readAlerts.addAll(readAlertsList);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading alerts from cache: $e');
    }
  }

  // Add multiple alerts at once
  void addAlerts(List<AlertItem> newAlerts) {
    _alerts.insertAll(0, newAlerts);
    _saveToCache();
    notifyListeners();
  }

  // Remove alerts by type
  void removeAlertsByType(String type) {
    _alerts.removeWhere((alert) => alert.type == type);
    _saveToCache();
    notifyListeners();
  }

  // Get alerts by type
  List<AlertItem> getAlertsByType(String type) {
    return _alerts.where((alert) => alert.type == type).toList();
  }

  // Get unread alerts
  List<AlertItem> get unreadAlerts {
    return _alerts.where((alert) => !isRead(alert)).toList();
  }
} 