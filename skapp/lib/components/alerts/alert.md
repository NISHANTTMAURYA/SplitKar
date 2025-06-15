# SplitKar Alert System

A real-time, optimized alert system for Flutter applications that handles individual alert updates without rebuilding the entire UI.

## Key Features

- Real-time updates with optimistic UI
- Per-alert state management
- Smooth animations
- Category-based filtering
- Memory efficient

## Creating Alerts

### 1. Basic Alert
```dart
// Create a simple notification alert
final alert = AlertItem(
  id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Welcome!',
  subtitle: 'Thanks for joining SplitKar',
  icon: Icons.notifications,
  actions: [],
  timestamp: DateTime.now(),
  category: AlertCategory.general,
);
```

### 2. Interactive Alert (e.g., Friend Request)
```dart
// Create friend request alert with actions
void sendFriendRequest(BuildContext context, String username) {
  final alert = AlertItem(
    id: 'friend_request_${requestId}',
    title: 'Friend Request',
    subtitle: '$username wants to be your friend',
    icon: Icons.person_add,
    actions: [
      AlertAction(
        label: 'Accept',
        onPressed: () => handleFriendRequest(true),
        color: Colors.green,
      ),
      AlertAction(
        label: 'Decline',
        onPressed: () => handleFriendRequest(false),
        color: Colors.red,
      ),
    ],
    timestamp: DateTime.now(),
    category: AlertCategory.friendRequest,
    requiresResponse: true,
  );

  // Add to service
  context.read<AlertService>().addAlert(alert);
}
```

### 3. Group Invitation Alert
```dart
// Create group invitation alert
void sendGroupInvite(BuildContext context, String groupName, String invitedBy) {
  final alert = AlertItem(
    id: 'group_invite_${inviteId}',
    title: 'Group Invitation',
    subtitle: '$invitedBy invited you to join $groupName',
    icon: Icons.group_add,
    imageUrl: groupImageUrl, // Optional group image
    actions: [
      AlertAction(
        label: 'Join',
        onPressed: () => handleGroupInvite(true),
        color: Colors.green,
      ),
      AlertAction(
        label: 'Skip',
        onPressed: () => handleGroupInvite(false),
        color: Colors.grey,
      ),
    ],
    timestamp: DateTime.now(),
    category: AlertCategory.groupInvite,
    requiresResponse: true,
  );
  
  context.read<AlertService>().addAlert(alert);
}
```

## Displaying Alerts

### 1. Show Alert Sheet
```dart
// In your widget/screen
ElevatedButton(
  onPressed: () => AlertSheet.show(context),
  child: Text('Show Alerts'),
)
```

### 2. Show Alert Count Badge
```dart
// In your app bar or navigation
Badge(
  label: Text(context.select(
    (AlertService s) => s.totalCount.toString(),
  )),
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () => AlertSheet.show(context),
  ),
)
```

### 3. Listen for Alert Updates
```dart
// In your widget
Consumer<AlertService>(
  builder: (context, service, child) {
    return Text('You have ${service.totalCount} notifications');
  },
)
```

## How It Works

### 1. Alert Service (Single Source of Truth)
```dart
class AlertService extends ChangeNotifier {
  List<AlertItem> _alerts = [];
  Set<String> _processingAlerts = {}; // Track processing state per alert
  
  // Optimistic update example
  Future<void> handleAlertAction(String alertId, Future<void> Function() action) async {
    _processingAlerts.add(alertId);
    _updateSingleAlert(alertId); // Update UI immediately
    
    try {
      await action(); // Execute in background
    } finally {
      _processingAlerts.remove(alertId);
    }
  }
}
```

### 2. Efficient UI Updates
```dart
// Instead of rebuilding entire list
ListView.builder(
  itemBuilder: (context, index) {
    return Selector<AlertService, bool>( // Only rebuild single alert
      selector: (_, service) => service.isProcessing(alert.id),
      builder: (context, isProcessing, child) => AlertCard(
        alert: alert,
        isProcessing: isProcessing,
      ),
    );
  },
)
```

## Best Practices

1. **Single Alert Updates**: Update individual alerts instead of the whole list
```dart
void _updateSingleAlert(String alertId) {
  _alerts.removeWhere((a) => a.id == alertId);
  notifyListeners(); // Only triggers rebuild for affected alert
}
```

2. **Optimistic Updates**: Update UI before API call completes
```dart
// In your widget
if (isProcessing) {
  return LoadingState(); // Show immediately
}
```

3. **Category Management**: Efficient filtering
```dart
final filteredAlerts = _selectedFilter == null
    ? alerts
    : alerts.where((a) => a.category == _selectedFilter);
```

## Performance Tips

- Use `Selector` for granular rebuilds
- Implement `shouldRebuild` for complex widgets
- Keep animations lightweight
- Cache filtered results when possible

For more details, check the implementation in `alert_service.dart` and `alert_sheet.dart`.
