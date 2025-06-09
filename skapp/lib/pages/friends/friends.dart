import 'package:skapp/pages/friends/add_friends_sheet.dart';

void _showAddFriendsSheet() {
  AddFriendsSheet.show(context);
}

// Example usage in a FloatingActionButton or similar
FloatingActionButton(
  onPressed: _showAddFriendsSheet,
  child: const Icon(Icons.person_add),
), 