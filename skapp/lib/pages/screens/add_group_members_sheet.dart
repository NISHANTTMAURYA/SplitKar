import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/pages/groups/group_service.dart';
import 'package:skapp/pages/groups/group_provider.dart';

class AddGroupMembersSheet extends StatefulWidget {
  final int groupId;
  final String groupName;
  final List<String> existingMemberCodes;
  final List<String> pendingInvitationCodes;

  const AddGroupMembersSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.existingMemberCodes,
    required this.pendingInvitationCodes,
  });

  static Future<bool> show(
    BuildContext context,
    int groupId,
    String groupName,
    List<String> existingMemberCodes,
    List<String> pendingInvitationCodes,
  ) {
    return showModalBottomSheet<bool>(
      barrierColor: Colors.deepPurple[400],
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => ChangeNotifierProvider(
          create: (_) => GroupProvider(),
          child: AddGroupMembersSheet(
            groupId: groupId,
            groupName: groupName,
            existingMemberCodes: existingMemberCodes,
            pendingInvitationCodes: pendingInvitationCodes,
          ),
        ),
      ),
    ).then((shouldRefresh) => shouldRefresh ?? false);
  }

  @override
  State<AddGroupMembersSheet> createState() => _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends State<AddGroupMembersSheet> {
  final TextEditingController _searchController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final GroupsService _groupsService = GroupsService();
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<GroupProvider>().loadUsers()
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                        context.read<GroupProvider>().searchUsers('');
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
                  context.read<GroupProvider>().searchUsers(value);
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
    final provider = context.watch<GroupProvider>();
    final profileCode = user['profile_code'];
    final isSelected = provider.selectedUsers.contains(profileCode);
    final isFriend = user['is_friend'] ?? false;
    final friendRequestStatus = user['friend_request_status'] ?? 'none';
    final isExistingMember = widget.existingMemberCodes.contains(profileCode);
    final hasPendingInvitation = widget.pendingInvitationCodes.contains(profileCode);

    // If this user is an existing member or has a pending invitation, they should be disabled
    final bool isDisabled = isExistingMember || hasPendingInvitation;

    // If the user is disabled and was previously selected, remove them from selection
    if (isDisabled && isSelected) {
      provider.removeUserFromSelection(profileCode);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          enabled: !isDisabled,
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                backgroundImage: user['profile_picture_url'] != null && user['profile_picture_url'].isNotEmpty && (user['profile_picture_url'] as String).startsWith('http')
                    ? CachedNetworkImageProvider(user['profile_picture_url'])
                    : null,
                child: user['profile_picture_url'] == null || user['profile_picture_url'].isEmpty || !(user['profile_picture_url'] as String).startsWith('http')
                    ? const Icon(Icons.person)
                    : null,
              ),
              if (isFriend)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            user['username'] ?? 'No Name',
            style: GoogleFonts.cabin(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Code: ${user['profile_code']}',
                style: GoogleFonts.cabin(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isExistingMember)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Already a Member',
                    style: GoogleFonts.cabin(
                      fontSize: 12,
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (hasPendingInvitation)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Invitation Pending',
                    style: GoogleFonts.cabin(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (isFriend)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Friend',
                    style: GoogleFonts.cabin(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          trailing: isDisabled
              ? null
              : Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (!isDisabled) {
                      provider.toggleUserSelection(profileCode);
                    }
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isInviting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomLoader(),
                const SizedBox(height: 16),
                Text(
                  _isInviting ? 'Inviting members...' : 'Loading users...',
                  style: GoogleFonts.cabin(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
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
                  onPressed: provider.loadUsers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show existing members and pending invitations at the top
        final existingMembers = provider.users.where((user) => 
          widget.existingMemberCodes.contains(user['profile_code'])).toList();
        final pendingUsers = provider.users.where((user) => 
          widget.pendingInvitationCodes.contains(user['profile_code'])).toList();

        // Filter out existing members and users with pending invitations first
        final availableUsers = provider.users.where((user) {
          final profileCode = user['profile_code'];
          return !widget.existingMemberCodes.contains(profileCode) &&
                 !widget.pendingInvitationCodes.contains(profileCode);
        }).toList();

        // Then separate friends and other users from available users
        final friends = availableUsers.where((user) => user['is_friend'] == true).toList();
        final otherUsers = availableUsers.where((user) => user['is_friend'] != true).toList();

        if (provider.users.isEmpty) {
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

        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo is ScrollEndNotification) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                      if (!provider.isLoadingMore && provider.hasMore) {
                        provider.loadMore();
                      }
                    }
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(),
                      if (existingMembers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Existing Members',
                            style: GoogleFonts.cabin(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: existingMembers.length,
                          itemBuilder: (context, index) => _buildUserTile(existingMembers[index]),
                        ),
                      ],
                      if (pendingUsers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Pending Invitations',
                            style: GoogleFonts.cabin(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingUsers.length,
                          itemBuilder: (context, index) => _buildUserTile(pendingUsers[index]),
                        ),
                      ],
                      if (friends.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Available Friends',
                            style: GoogleFonts.cabin(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: friends.length,
                          itemBuilder: (context, index) => _buildUserTile(friends[index]),
                        ),
                      ],
                      if (otherUsers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Other Available Users',
                            style: GoogleFonts.cabin(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: otherUsers.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == otherUsers.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: CustomLoader(
                                    size: 30,
                                    isButtonLoader: true,
                                  ),
                                ),
                              );
                            }
                            return _buildUserTile(otherUsers[index]);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: provider.selectedUsers.isEmpty
                    ? null
                    : () async {
                        try {
                          setState(() => _isInviting = true);
                          
                          final result = await _groupsService.inviteToGroup(
                            groupId: widget.groupId,
                            profileCodes: provider.selectedUsers.toList(),
                          );
                          
                          if (mounted) {
                            final invitationCount = result['invitations'].length;
                            final invitedUsers = result['invitations']
                                .map((inv) => inv['invited_user_username'] as String)
                                .toList();
                            
                            final message = invitationCount == 1
                                ? '${invitedUsers.first} has been invited to ${widget.groupName}'
                                : '${invitedUsers.join(", ")} have been invited to ${widget.groupName}';
                            
                            _notificationService.showAppNotification(
                              context,
                              title: 'Members Invited',
                              message: message,
                              icon: Icons.group_add,
                            );
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (mounted) {
                            _notificationService.showAppNotification(
                              context,
                              title: 'Error',
                              message: e.toString(),
                              icon: Icons.error_outline,
                              isImportant: true,
                            );
                            setState(() => _isInviting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Invite to ${widget.groupName} (${provider.selectedUsers.length} selected)',
                  style: GoogleFonts.cabin(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              'Add Members to ${widget.groupName}',
              style: GoogleFonts.cabin(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
} 