import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/pages/screens/group_settings_api.dart';

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
      subtitle: member['profile_code'] != null
          ? Text(member['profile_code'])
          : const Text('No profile code'),
      trailing: isAdmin
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 12,
                ),
              ),
            )
          : null,
    );
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
                              child: Text(
                                'Members',
                                style: Theme.of(context).textTheme.titleLarge,
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
