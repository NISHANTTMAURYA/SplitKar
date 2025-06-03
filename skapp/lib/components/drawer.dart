import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.deepPurple[400],
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                  ),
                  SizedBox(width: 16),
                  Text(
                    'SplitKar',
                    style: GoogleFonts.cabin(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.group, color: Colors.white),
              title: Text('Groups', style: TextStyle(color: Colors.white)),
              selected: selectedIndex == 0,
              selectedTileColor: Colors.deepPurple.withOpacity(0.2),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/groups');
                onItemSelected(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text('Friends', style: TextStyle(color: Colors.white)),
              selected: selectedIndex == 1,
              selectedTileColor: Colors.deepPurple.withOpacity(0.2),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/freinds');
                onItemSelected(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_activity, color: Colors.white),
              title: Text('Activity', style: TextStyle(color: Colors.white)),
              selected: selectedIndex == 2,
              selectedTileColor: Colors.deepPurple.withOpacity(0.2),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/activity');
                onItemSelected(2);
              },
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Navigate to settings page
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
