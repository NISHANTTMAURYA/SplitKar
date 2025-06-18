import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({super.key});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  // Dummy data for demonstration
  final List<Map<String, dynamic>> members = [
    {
      'username': 'John Doe',
      'profile_picture_url': null,
      'is_admin': true,
    },
    {
      'username': 'Jane Smith',
      'profile_picture_url': null,
      'is_admin': false,
    },
    {
      'username': 'Mike Johnson',
      'profile_picture_url': null,
      'is_admin': false,
    },
    // Add more dummy members as needed
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final avatarSize = width * 0.2; // 20% of screen width for the main group avatar

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: height * 0.02,
                      left: width * 0.04,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                    child: Icon(
                      Icons.groups_2_outlined,
                      size: avatarSize * 0.6,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    'Trip to Goa',  // Example group name
                    style: GoogleFonts.cabin(
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '6 members',  // Example member count
                    style: GoogleFonts.cabin(
                      fontSize: width * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.02,
                    ),
                    color: Colors.grey[100],
                    child: Text(
                      'Members',
                      style: GoogleFonts.cabin(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final member = members[index];
                final memberAvatarSize = width * 0.12; // Smaller avatars for list

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.01,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: width * 0.015,
                      ),
                      leading: CircleAvatar(
                        radius: memberAvatarSize / 2.2,
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        child: Icon(
                          Icons.person,
                          size: memberAvatarSize * 0.6,
                          color: Colors.grey[400],
                        ),
                      ),
                      title: Text(
                        member['username'],
                        style: GoogleFonts.cabin(
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: member['is_admin']
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: width * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[50],
                                borderRadius: BorderRadius.circular(width * 0.02),
                                border: Border.all(
                                  color: Colors.deepPurple[200]!,
                                ),
                              ),
                              child: Text(
                                'Admin',
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
              childCount: members.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: height * 0.1),
          ),
        ],
      ),
    );
  }
}
