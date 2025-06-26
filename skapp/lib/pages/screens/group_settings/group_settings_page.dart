import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/pages/screens/group_settings/group_settings_api.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/pages/screens/group_settings/add_group_members_sheet.dart';
import 'package:skapp/utils/app_colors.dart';

class ExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final Function(bool)? onExpandChanged;

  const ExpandableCard({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.onExpandChanged,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconTurns;
  bool _isExpanded = false;

  static const Duration _animationDuration = Duration(milliseconds: 300);
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpandChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AppColorScheme>()!.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // Optimized opacity
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.header,
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: RotationTransition(
                        turns: _iconTurns,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: _animationDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: widget.content,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupSettingsPage extends StatefulWidget {
  final int groupId;

  const GroupSettingsPage({super.key, required this.groupId});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final GroupSettingsApi _api = GroupSettingsApi();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildEnhancedMemberTile(Map<String, dynamic> member) {
    final bool isAdmin = _groupDetails!['admins'].any(
          (admin) => admin['id'] == member['id'],
    );
    final bool currentUserIsAdmin = _groupDetails!['is_admin'] ?? false;
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    return Container(
      decoration: BoxDecoration(
        color: appColors.subtitleColor1?.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),

      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Enhanced Avatar
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isAdmin ? (appColors.borderColor2 ?? Colors.blue[800]!.withOpacity(0.8)) : (appColors.borderColor3 ?? Colors.grey.withOpacity(0.8)),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: member['profile_picture_url'] != null
                        ? CachedNetworkImageProvider(member['profile_picture_url'])
                        : null,
                    backgroundColor: isAdmin
                        ? (appColors.borderColor2 ?? Colors.blue.withOpacity(0.1))
                        : (appColors.borderColor3 ?? Colors.grey.withOpacity(0.1)),
                    child: member['profile_picture_url'] == null
                        ? Text(
                      member['username'][0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? (appColors.borderColor2 ?? Colors.blue) : (appColors.textColor2 ?? Colors.grey[700]),
                      ),
                    )
                        : null,
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: appColors.borderColor2,
                        gradient: LinearGradient(
                          colors: [appColors.borderColor2!.withOpacity(0.8), appColors.borderColor2 ?? Colors.blue[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member['username'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color:  appColors.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [appColors.borderColor2!.withOpacity(0.4), appColors.borderColor2 ?? Colors.blue[800]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (appColors.borderColor2 ?? Colors.blue).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [


                      Text(
                        member['profile_code'] ?? 'No profile code',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.subtitleColor2 ,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Button
            if (currentUserIsAdmin && !isAdmin)
              Container(
                margin: const EdgeInsets.only(left: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showRemoveConfirmation(member),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.iconColor2?.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appColors.iconColor2 ?? Colors.red, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: (appColors.iconColor2 ?? Colors.red).withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_remove,
                        color: appColors.iconColor2 ?? backgroundColordarkmode!,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmation(Map<String, dynamic> member) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove ${member['username']}?'),
          content: Text(
            'Are you sure you want to remove ${member['username']} from this group?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    final appColor = Theme.of(context).extension<AppColorScheme>()!;

    final header = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appColor.cardColor2!,
            appColor.cardColor2!.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flight_takeoff,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Trip Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildEnhancedTripDetailRow(Icons.location_on, 'Destination', tripDetails['destination'], appColor.iconColor2 ?? Colors.red),
          _buildEnhancedTripDetailRow(Icons.calendar_today, 'Start Date', tripDetails['start_date'], appColor.iconColor2 ?? Colors.green),
          _buildEnhancedTripDetailRow(Icons.event, 'End Date', tripDetails['end_date'], appColor.iconColor2 ?? Colors.orange),
          _buildEnhancedTripDetailRow(Icons.info_outline, 'Status', tripDetails['trip_status'], appColor.iconColor2 ?? Colors.orange),
          if (tripDetails['budget'] != null)
            _buildEnhancedTripDetailRow(Icons.account_balance_wallet, 'Budget', '₹${tripDetails['budget']}', appColor.iconColor2 ?? Colors.purple),
        ],
      ),
    );

    return ExpandableCard(
      header: header,
      content: content,
      initiallyExpanded: false,
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _scrollToBottom();
        }
      },
    );
  }

  Widget _buildEnhancedTripDetailRow(IconData icon, String label, String? value, Color iconColor) {
    if (value == null) return const SizedBox.shrink();
    final appColor = Theme.of(context).extension<AppColorScheme>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor.subtitleColor1?.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),

            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: appColor.subtitleColor2)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14,)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    if (_groupDetails == null) return const SizedBox.shrink();
    final appColor = Theme.of(context).extension<AppColorScheme>()!;

    final header = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColor.cardColor2!, appColor.cardColor2!.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.group, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            'Group Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appColor.subtitleColor1?.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: appColor.iconColor2, size: 20),
                    const SizedBox(width: 6),
                    Text('Description', style: TextStyle(fontSize: 16, color: appColor.subtitleColor2,fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_groupDetails!['description'] ?? 'No description available',style: TextStyle(fontWeight: FontWeight.w500),),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColor.subtitleColor1?.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person, color: appColor.iconColor2, size: 24),
                      const SizedBox(height: 4),
                      Text('Created by', style: TextStyle(fontSize: 14, color: appColor.subtitleColor2,fontWeight: FontWeight.bold)),
                      Text(_groupDetails!['created_by']['username'], style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColor.subtitleColor1?.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people, color: appColor.iconColor2, size: 24),
                      const SizedBox(height: 4),
                      Text('Members', style: TextStyle(fontSize: 14, color: appColor.subtitleColor2,fontWeight: FontWeight.bold)),
                      Text('${_groupDetails!['member_count']}', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColor.subtitleColor1?.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: appColor.iconColor2, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created', style: TextStyle(fontSize: 14, color: appColor.subtitleColor2, fontWeight: FontWeight.bold)),
                    Text(
                      _formatDateTime(_groupDetails!['created_at']),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return ExpandableCard(
      header: header,
      content: content,
      initiallyExpanded: false,
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _scrollToBottom();
        }
      },
    );
  }

  Widget _buildMembersCard() {
    if (_groupDetails == null) return const SizedBox.shrink();
    final appColor = Theme.of(context).extension<AppColorScheme>()!;

    return ExpandableCard(
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _scrollToBottom();
        }
      },
      header: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              appColor.cardColor2!,
              appColor.cardColor2!.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_groupDetails!['members'].length} travelers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_groupDetails!['is_admin'] ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final existingMemberCodes = List<String>.from(
                        _groupDetails!['members'].map(
                              (member) => member['profile_code'] as String,
                        ),
                      );

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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add Members',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groupDetails!['members'].length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _groupDetails!['members'][index];
                return _buildEnhancedMemberTile(member);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColor = Theme.of(context).extension<AppColorScheme>()!;
    return _isLoading
        ? Container(color:backgroundColordarkmode,child: Center(child: CustomLoader()))
        : Scaffold(
            appBar: AppBar(
              title: Text(_groupDetails?['name'] ?? 'Group Settings'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                      controller: _scrollController,
                      children: [
                        // Group Info Card
                        _buildGroupInfoCard(),

                        // Trip Details Card (if applicable)
                        _buildTripDetails(),

                        // Members List Card
                        _buildMembersCard(),
                      ],
                    ),
                  ),
          );
  }

  String _formatDateTime(String dateTimeStr) {
    final DateTime dateTime = DateTime.parse(dateTimeStr);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    // List of month names
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Format time
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    hour = hour == 0 ? 12 : hour; // Convert 0 to 12 for 12 AM
    String time = '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';

    // Format date with month name
    String fullDate = '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';

    // Add relative time
    String relativeTime;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        relativeTime = '${difference.inMinutes} minutes ago';
      } else {
        relativeTime = '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      relativeTime = 'yesterday';
    } else if (difference.inDays < 7) {
      relativeTime = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      relativeTime = '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      relativeTime = fullDate;
    }

    return '$fullDate at $time\n($relativeTime)';
  }
}
