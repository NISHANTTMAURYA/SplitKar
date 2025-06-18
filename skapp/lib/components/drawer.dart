import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // For ProfileNotifier
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:logging/logging.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<String> labels;
  final List<IconData> icons;
  final _logger = Logger('AppDrawer');

  AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.labels,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileNotifier>(context);
    final navigationService = Provider.of<NavigationService>(
      context,
      listen: false,
    );
    final currentRoute = ModalRoute.of(context)?.settings.name;

    _logger.info('Current route: $currentRoute');
    _logger.info('Selected index: $selectedIndex');

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
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (profile.photoUrl != null &&
                          profile.photoUrl!.isNotEmpty && profile.photoUrl!.startsWith('http'))
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
                      SizedBox(height: 4),
                      if (profile.profileCode != null && profile.profileCode!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Profile Code: ',
                                style: GoogleFonts.cabin(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                profile.profileCode!,
                                style: GoogleFonts.cabin(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurple[300]?.withOpacity(
                            0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          _logger.info('Profile Settings button pressed');
                          _logger.info('Current route: $currentRoute');

                          // Close drawer first
                          Navigator.pop(context);

                          if (currentRoute == '/settings') {
                            _logger.info(
                              'Already on settings page, preventing navigation',
                            );
                            return;
                          }

                          _logger.info('Navigating to settings page');
                          navigationService.navigateToSettings();
                        },
                        icon: Icon(Icons.settings, color: Colors.white),
                        label: Text(
                          'Profile Settings',
                          style: GoogleFonts.cabin(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Colors.white54,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),

              // Better approach - Replace your drawer items generation with this:

              ...List.generate(labels.length, (index) {
                return ListTile(
                  leading: Icon(icons[index], color: Colors.white),
                  title: Text(
                    labels[index],
                    style: GoogleFonts.cabin(color: Colors.white, fontSize: 17),
                  ),
                  selected: selectedIndex == index,
                  selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    _logger.info('Drawer item tapped: ${labels[index]} (index: $index)');
                    _logger.info('Current route before navigation: $currentRoute');

                    // Close drawer first
                    Navigator.pop(context);

                    // Always allow navigation from settings page to main page items
                    // Only prevent navigation if trying to go to settings while already on settings
                    if (currentRoute == '/main') {
                      _logger.info('On main page, switching to index: $index');
                      onItemSelected(index);
                    } else {
                      // Coming from settings or other pages - always navigate to main
                      _logger.info('Navigating to main with index: $index');
                      navigationService.navigateToMain(initialIndex: index);
                    }
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
