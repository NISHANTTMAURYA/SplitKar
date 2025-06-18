import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/pages/screens/group_settings_api.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/pages/screens/add_group_members_sheet.dart';

class GroupSettingsPage extends StatefulWidget {
  final int groupId;

  const GroupSettingsPage({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final GroupSettingsApi _api = GroupSettingsApi();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _groupDetails;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final details = await _api.getGroupDetails(widget.groupId);
      setState(() {
        _groupDetails = details;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final bool isAdmin = _groupDetails!['admins']
        .any((admin) => admin['id'] == member['id']);
    final bool currentUserIsAdmin = _groupDetails!['is_admin'] ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member['profile_picture_url'] != null
            ? CachedNetworkImageProvider(member['profile_picture_url'])
            : null,
        child: member['profile_picture_url'] == null
            ? Text(member['username'][0].toUpperCase())
            : null,
      ),
      title: Text(member['username']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          member['profile_code'] != null
              ? Text(member['profile_code'])
              : const Text('No profile code'),
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      trailing: currentUserIsAdmin && !isAdmin
          ? Container(
              margin: const EdgeInsets.only(left: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showRemoveConfirmation(member),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red[700],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _showRemoveConfirmation(Map<String, dynamic> member) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove ${member['username']}?'),
          content: Text('Are you sure you want to remove ${member['username']} from this group?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        await _api.removeMember(widget.groupId, member['profile_code']);
        if (mounted) {
          _notificationService.showAppNotification(
            context,
            title: 'Member Removed',
            message: '${member['username']} has been removed from the group',
            icon: Icons.person_remove,
            duration: const Duration(seconds: 3),
          );
          // Refresh group details
          _fetchGroupDetails();
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
        }
      }
    }
  }

  Widget _buildTripDetails() {
    if (_groupDetails == null || _groupDetails!['group_type'] != 'trip') {
      return const SizedBox.shrink();
    }

    final tripDetails = _groupDetails!['trip_details'];
    if (tripDetails == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTripDetailRow('Destination', tripDetails['destination']),
            _buildTripDetailRow('Start Date', tripDetails['start_date']),
            _buildTripDetailRow('End Date', tripDetails['end_date']),
            _buildTripDetailRow('Status', tripDetails['trip_status']),
            if (tripDetails['budget'] != null)
              _buildTripDetailRow('Budget', '₹${tripDetails['budget']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupDetails?['name'] ?? 'Group Settings'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchGroupDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchGroupDetails,
                  child: ListView(
                    children: [
                      // Group Info Card
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Group Information',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(_groupDetails!['description'] ?? 'No description'),
                              const SizedBox(height: 16),
                              Text(
                                'Created by: ${_groupDetails!['created_by']['username']}',
                              ),
                              Text(
                                'Members: ${_groupDetails!['member_count']}',
                              ),
                              Text(
                                'Created at: ${_groupDetails!['created_at']}',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Trip Details Card (if applicable)
                      _buildTripDetails(),

                      // Members List Card
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Members',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (_groupDetails!['is_admin'] ?? false)
                                    TextButton.icon(
                                      onPressed: () {
                                        // Get existing member profile codes
                                        final existingMemberCodes = List<String>.from(
                                          _groupDetails!['members'].map((member) => member['profile_code'] as String)
                                        );

                                        // Get pending invitation profile codes - include both sent and received invitations
                                        final sentInvitations = (_groupDetails!['sent_invitations'] ?? [])
                                            .map((invitation) => invitation['invited_user_profile_code'] as String);
                                        final receivedInvitations = (_groupDetails!['received_invitations'] ?? [])
                                            .map((invitation) => invitation['invited_user_profile_code'] as String);
                                        
                                        final pendingInvitationCodes = List<String>.from([
                                          ...sentInvitations,
                                          ...receivedInvitations,
                                        ]);

                                        AddGroupMembersSheet.show(
                                          context,
                                          widget.groupId,
                                          _groupDetails!['name'],
                                          existingMemberCodes,
                                          pendingInvitationCodes,
                                        ).then((shouldRefresh) {
                                          if (shouldRefresh) {
                                            _fetchGroupDetails();
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Add'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _groupDetails!['members'].length,
                              itemBuilder: (context, index) {
                                final member = _groupDetails!['members'][index];
                                return _buildMemberTile(member);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
