import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/services/alert_service.dart';

import '../../widgets/bottom_sheet_wrapper.dart';
import 'group_provider.dart';

class AddFriendsSheet extends StatefulWidget {
  const AddFriendsSheet({super.key});

  static Future<bool> show(BuildContext context) {
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
          child: const AddFriendsSheet(),
        ),
      ),
    ).then((shouldRefresh) => shouldRefresh ?? false);
  }

  @override
  State<AddFriendsSheet> createState() => _AddFriendsSheetState();
}

class _AddFriendsSheetState extends State<AddFriendsSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String _selectedGroupType = 'regular';
  String _selectedTripStatus = 'planned';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreatingGroup = false;

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
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (mounted) {
      Navigator.pop(context);
    }
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
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
            style: GoogleFonts.cabin(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Code: ${user['profile_code']}',
                style: GoogleFonts.cabin(fontSize: 12, color: Colors.grey[600]),
              ),
              if (isFriend)
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
                )
              else if (friendRequestStatus == 'sent')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Friend Request Sent',
                    style: GoogleFonts.cabin(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (friendRequestStatus == 'received')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Friend Request Received',
                    style: GoogleFonts.cabin(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) {
              provider.toggleUserSelection(profileCode);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTripGroupFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _destinationController,
          decoration: InputDecoration(
            labelText: 'Destination',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_startDate == null 
                  ? 'Start Date' 
                  : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate == null 
                  ? 'End Date' 
                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedTripStatus,
          decoration: InputDecoration(
            labelText: 'Trip Status',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'planned', child: Text('Planned')),
            DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedTripStatus = value);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _budgetController,
          decoration: InputDecoration(
            labelText: 'Budget (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixText: '₹',
            hintText: 'Enter amount in Indian Rupees',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildGroupCreationForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Group',
            style: GoogleFonts.cabin(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupDescriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGroupType,
            decoration: InputDecoration(
              labelText: 'Group Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'regular',
                child: Text('Regular Group'),
              ),
              DropdownMenuItem(
                value: 'trip',
                child: Text('Trip Group'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedGroupType = value);
              }
            },
          ),
          if (_selectedGroupType == 'trip') ...[
            const SizedBox(height: 16),
            _buildTripGroupFields(),
          ],
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return false;
    }

    if (_selectedGroupType == 'trip') {
      if (_destinationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a destination')),
        );
        return false;
      }
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date')),
        );
        return false;
      }
      if (_endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an end date')),
        );
        return false;
      }
      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start date cannot be after end date')),
        );
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider = context.read<GroupProvider>();
        if (provider.isLoading) {
          return false;
        }
        return true;
      },
      child: Container(
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
                'Create Group',
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
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomLoader(),
                const SizedBox(height: 16),
                Text(
                  'Creating group...',
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

        // Separate friends and other users
        final friends = provider.users.where((user) => user['is_friend'] == true).toList();
        final otherUsers = provider.users.where((user) => user['is_friend'] != true).toList();

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
                      _buildGroupCreationForm(),
                      _buildSearchField(),
                      if (friends.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Friends',
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
                            'Other Users',
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
                        if (!_validateForm()) return;
                        
                        // Hide keyboard before showing loading
                        FocusScope.of(context).unfocus();
                        
                        try {
                          final success = await provider.createGroupAndInvite(
                            context: context,
                            name: _groupNameController.text,
                            description: _groupDescriptionController.text,
                            groupType: _selectedGroupType,
                            destination: _selectedGroupType == 'trip' ? _destinationController.text : null,
                            startDate: _selectedGroupType == 'trip' ? _startDate : null,
                            endDate: _selectedGroupType == 'trip' ? _endDate : null,
                            tripStatus: _selectedGroupType == 'trip' ? _selectedTripStatus : null,
                            budget: _selectedGroupType == 'trip' && _budgetController.text.isNotEmpty
                                ? double.tryParse(_budgetController.text)
                                : null,
                          );
                          
                          if (mounted && success) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
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
                  'Create Group (${provider.selectedUsers.length} selected)',
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
}
