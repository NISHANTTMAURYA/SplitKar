import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skapp/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  GoogleSignInAccount? _account;

  // Use the same labels and icons as in main_page.dart
  final List<String> labels = ['Groups', 'Friends', 'Activity'];
  final List<IconData> icons = [Icons.group, Icons.person, Icons.local_activity];

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final account = await GoogleSignIn().signInSilently();
    setState(() {
      _account = account;
    });
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_account != null) ...[
              CircleAvatar(
                backgroundImage: _account!.photoUrl != null ? NetworkImage(_account!.photoUrl!) : null,
                radius: 32,
                child: _account!.photoUrl == null ? Icon(Icons.person, size: 32) : null,
              ),
              SizedBox(height: 12),
              Text(_account!.displayName ?? 'No Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_account!.email, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
