import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // For ProfileNotifier
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<String> labels;
  final List<IconData> icons;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.labels,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileNotifier>(context);
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.deepPurple[400]!.withOpacity(1),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profile.photoUrl!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CustomLoader(
                                  size: 30,
                                  isButtonLoader: true,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 44,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: Image.asset(
                            'assets/images/profile_placeholder.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(height: 16),
                      Text(
                        profile.name ?? 'Your Name',
                        style: GoogleFonts.cabin(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '@${profile.username ?? 'username'}',
                        style: GoogleFonts.cabin(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurple[300]?.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        },
                        icon: Icon(Icons.settings, color: Colors.white),
                        label: Text('Profile Settings', style: GoogleFonts.cabin()),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: Colors.white54, thickness: 1, indent: 16, endIndent: 16),

              ...List.generate(labels.length, (index) {
                return ListTile(
                  leading: Icon(icons[index], color: Colors.white),
                  title: Text(
                    labels[index],
                    style: GoogleFonts.cabin(color: Colors.white, fontSize: 17),
                  ),
                  selected: selectedIndex == index,
                  selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  onTap: () {
                    Navigator.pop(context);
                    onItemSelected(index);
                  },
                  hoverColor: Colors.deepPurple[200]?.withOpacity(0.15),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
