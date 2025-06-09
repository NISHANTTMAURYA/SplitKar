import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'friends_provider.dart';

class AddFriendsSheet extends StatefulWidget {
  // Allow both private and public construction
  const AddFriendsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => ChangeNotifierProvider(
          create: (_) => FriendsProvider(),
          child: const AddFriendsSheet(),
        ),
      ),
    );
  }

  @override
  State<AddFriendsSheet> createState() => _AddFriendsSheetState();
}

class _AddFriendsSheetState extends State<AddFriendsSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load users when sheet opens
    Future.microtask(() => 
      context.read<FriendsProvider>().loadPotentialFriends()
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Type name or profile code (e.g. VINISH@8T62)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<FriendsProvider>().searchUsers('');
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            onChanged: (value) {
              // Debounce the search
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _searchController.text == value) {
                  context.read<FriendsProvider>().searchUsers(value);
                }
              });
            },
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final provider = context.watch<FriendsProvider>();
    final profileCode = user['profile_code'];
    final isPending = provider.isPending(profileCode);
    final requestStatus = user['friend_request_status'] as String? ?? 'none';

    Widget trailingWidget;
    
    if (requestStatus == 'sent' || isPending) {
      trailingWidget = TextButton.icon(
        icon: const Icon(Icons.hourglass_empty),
        label: const Text('Pending'),
        onPressed: null,
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
      );
    } else if (requestStatus == 'received') {
      trailingWidget = TextButton.icon(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Respond'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your pending requests to respond'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      trailingWidget = TextButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
        onPressed: () => context.read<FriendsProvider>().sendFriendRequest(context, user),
      );
    }

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
            backgroundImage: user['profile_picture_url'] != null && user['profile_picture_url'].isNotEmpty
                ? CachedNetworkImageProvider(user['profile_picture_url'])
                : null,
            child: user['profile_picture_url'] == null || user['profile_picture_url'].isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            user['username'] ?? 'No Name',
            style: GoogleFonts.cabin(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Profile Code: ${user['profile_code']}',
            style: GoogleFonts.cabin(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: trailingWidget,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CustomLoader());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[300]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadPotentialFriends,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = provider.potentialFriends;
        if (users.isEmpty) {
          return Center(
            child: Text(
              _searchController.text.isEmpty
                ? 'No users available to add'
                : 'No users found matching "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!provider.isLoadingMore && provider.hasMore &&
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              provider.loadMore();
            }
            return true;
          },
          child: ListView.builder(
            itemCount: users.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == users.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CustomLoader(
                      size: 30,
                      isButtonLoader: true,
                    ),
                  ),
                );
              }
              return _buildUserTile(users[index]);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Friends',
              style: GoogleFonts.cabin(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildSearchField(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 