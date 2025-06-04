import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/pages/main_page.dart';

class SettingsPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Use the same labels and icons as in main_page.dart
  final List<String> labels = ['Groups', 'Friends', 'Activity'];
  final List<IconData> icons = [Icons.group, Icons.person, Icons.local_activity];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      drawer: AppDrawer(
        selectedIndex: -1, // Settings doesn't have an index in bottom nav
        onItemSelected: (index) {
          _scaffoldKey.currentState?.closeDrawer();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(initialIndex: index),
            ),
          );
        },
        labels: labels,
        icons: icons,
      ),
      body: Center(child: Text('Settings Page')),
    );
  }
}
