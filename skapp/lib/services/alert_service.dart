import 'package:flutter/material.dart';
import 'package:skapp/components/alert_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:provider/provider.dart';

class AlertService extends ChangeNotifier {
  static const String _alertsCacheKey = 'cached_alerts';
  List<AlertItem> _alerts = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  final Set<String> _readAlerts = {};

  // Getters
  List<AlertItem> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get totalCount => _alerts.where((alert) => !_readAlerts.contains(_getAlertId(alert))).length;

  AlertService() {
    _loadFromCache();
  }

  // Initialize alerts
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      await _loadFromCache();
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing alerts: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show alert sheet
  void showAlertSheet(BuildContext context) {
    // Create a new builder context to ensure proper provider access
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
            // Load friend requests using the new context
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
                friendsProvider.loadPendingRequests(context);
              }
            });

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

  // Add a new alert with deduplication
  void addAlert(AlertItem alert) {
    // Check if an alert with the same type already exists
    final existingIndex = _alerts.indexWhere((a) => a.type == alert.type);
    if (existingIndex != -1) {
      // Update existing alert
      _alerts[existingIndex] = alert;
    } else {
      // Add new alert to the beginning of the list
      _alerts.insert(0, alert);
    }
    _saveToCache();
    notifyListeners();
  }

  // Add multiple alerts at once with deduplication
  void addAlerts(List<AlertItem> newAlerts) {
    bool hasChanges = false;
    
    for (final alert in newAlerts) {
      final existingIndex = _alerts.indexWhere((a) => a.type == alert.type);
      if (existingIndex != -1) {
        if (_alerts[existingIndex].timestamp != alert.timestamp) {
          _alerts[existingIndex] = alert;
          hasChanges = true;
        }
      } else {
        _alerts.insert(0, alert);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _saveToCache();
      notifyListeners();
    }
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

  // Save alerts to cache with error handling
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

  // Load alerts from cache with error handling
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

        // Sort alerts by timestamp
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      if (readAlertsList != null) {
        _readAlerts.addAll(readAlertsList);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading alerts from cache: $e');
    }
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