import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:skapp/pages/screens/group_settings/group_settings_page.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatName;
  final String? chatImageUrl;
  final int groupId;

  const GroupChatScreen({
    super.key,
    required this.chatName,
    this.chatImageUrl,
    required this.groupId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  @override
  Widget build(BuildContext context) {
    final double avatarSize = MobileUtils.getScreenWidth(context) * 0.1; // Responsive avatar size (e.g., 10% of screen width)

    return Scaffold(
      appBar: PreferredSize(  
        preferredSize: Size.fromHeight(MobileUtils.getScreenHeight(context) * 0.08), // Adjusted AppBar height for responsiveness
        child: AppBar(
          automaticallyImplyLeading: false, // Control leading manually
          toolbarHeight: MobileUtils.getScreenHeight(context) * 0.08, // Set the actual toolbar height
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton( // Back button
            icon: const Icon(Icons.arrow_back, color: Colors.white), // Assuming white icon for purple background
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          titleSpacing: 0.0, // Remove default spacing between leading and title
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsPage(groupId: widget.groupId),
                ),
              );
            },
            child: Row( // Avatar and chat name
              children: [
                Padding(
                  padding: EdgeInsets.only(right: MobileUtils.getScreenWidth(context) * 0.02), // Responsive padding
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                    child: ClipOval(
                      child: (widget.chatImageUrl != null &&
                              widget.chatImageUrl!.isNotEmpty &&
                              widget.chatImageUrl!.startsWith('http'))
                          ? CachedNetworkImage(
                              imageUrl: widget.chatImageUrl!,
                              placeholder: (context, url) => CustomLoader(
                                size: avatarSize * 0.6,
                                isButtonLoader: true,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.groups_2_outlined,
                                size: avatarSize * 0.6,
                                color: Colors.grey[400],
                              ),
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.groups_2_outlined,
                              size: avatarSize * 0.6,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                ),
                Expanded( // Chat name
                  child: Text(
                    widget.chatName,
                    overflow: TextOverflow.ellipsis, // Ensure text truncates if too long
                    maxLines: 1, // Ensure text doesn't wrap
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white), // Use appropriate text style and ensure white color
                  ),
                ),

              ],
            ),
          ),
          // No centerTitle needed when using leading and title directly, defaults to false for custom title layouts
        ),
      ),
      body: const Center(

        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // CustomLoader(),
            Text('working on it')
          ],
        ), // Replaced text with CustomLoader
      ),
    );
  }
}
