import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/components/bottomNavbar.dart';

class FreindsPage extends StatefulWidget {
  @override
  State<FreindsPage> createState() => _FreindsPageState();
}

class _FreindsPageState extends State<FreindsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: Center(child: Text('Friends Page')),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
