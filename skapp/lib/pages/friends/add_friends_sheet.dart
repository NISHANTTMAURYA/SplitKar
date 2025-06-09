import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';

class AddFriendsSheet extends StatefulWidget {
  const AddFriendsSheet({super.key});

  @override
  State<AddFriendsSheet> createState() => _AddFriendsSheetState();
}

class _AddFriendsSheetState extends State<AddFriendsSheet> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _dummyUsers = [
    {
      'username': 'John Doe',
      'profile_picture_url': '',
      'profile_code': 'JOHN123'
    },
    {
      'username': 'Jane Smith',
      'profile_picture_url': '',
      'profile_code': 'JANE456'
    },
    {
      'username': 'Alice Johnson',
      'profile_picture_url': '',
      'profile_code': 'ALICE789'
    },
    {
      'username': 'Bob Wilson',
      'profile_picture_url': '',
      'profile_code': 'BOB101'
    },
    {
      'username': 'Emma Davis',
      'profile_picture_url': '',
      'profile_code': 'EMMA202'
    },
  ];

  List<Map<String, dynamic>> _getFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _dummyUsers;
    
    return _dummyUsers.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      return username.contains(query);
    }).toList();
  }

  void _showAddedSnackbar(String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to $username!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add Friends',
              style: GoogleFonts.cabin(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          // Users list
          Expanded(
            child: ListView.builder(
              itemCount: _getFilteredUsers().length,
              itemBuilder: (context, index) {
                final user = _getFilteredUsers()[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .inversePrimary
                            .withOpacity(0.7),
                        child: const Icon(Icons.person),
                      ),
                      title: Text(
                        user['username'] ?? 'No Name',
                        style: GoogleFonts.cabin(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add'),
                        onPressed: () => _showAddedSnackbar(user['username']),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 