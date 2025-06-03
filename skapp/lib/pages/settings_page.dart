import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';

class SettingsPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      drawer: AppDrawer(
        selectedIndex: -1, // Settings doesn't have an index in bottom nav
        onItemSelected: (index) {
          // Handle navigation
        },
      ),
      body: Center(child: Text('Settings Page')),
    );
  }
}
