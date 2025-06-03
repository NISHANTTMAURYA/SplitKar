import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<String> labels;
  final List<IconData> icons;

  const AppDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.labels,
    required this.icons,
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
            ...List.generate(labels.length, (index) {
              return ListTile(
                leading: Icon(icons[index], color: Colors.white),
                title: Text(labels[index], style: TextStyle(color: Colors.white)),
                selected: selectedIndex == index,
                selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                onTap: () {
                  Navigator.pop(context);
                  onItemSelected(index);
                },
              );
            }),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
