import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:provider/provider.dart';
import 'package:skapp/main.dart'; // For ProfileNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> labels = ['Groups', 'Friends', 'Activity'];
  final List<IconData> icons = [
    Icons.group,
    Icons.person,
    Icons.local_activity,
  ];

  @override
  Widget build(BuildContext context) {
    final ScreenHeight = MediaQuery.of(context).size.height;
    final ScreenWidth = MediaQuery.of(context).size.width;
    final profile = Provider.of<ProfileNotifier>(context);

    // Show loader if profile data is loading
    if (profile.isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(scaffoldKey: _scaffoldKey, is_bottom_needed: false),
        drawer: AppDrawer(
          selectedIndex: -1,
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
        body: CustomLoader(),
      );
    }

    // Show error if there is one
    if (profile.error != null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(scaffoldKey: _scaffoldKey, is_bottom_needed: false),
        drawer: AppDrawer(
          selectedIndex: -1,
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
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                profile.error!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ProfileApi().loadAllProfileData(context);
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show profile content if data is available
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey, is_bottom_needed: false),
      drawer: AppDrawer(
        selectedIndex: -1,
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
      body: _ProfileContent(
        profile: profile,
        screenWidth: ScreenWidth,
        screenHeight: ScreenHeight,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileNotifier profile;
  final double screenWidth;
  final double screenHeight;

  const _ProfileContent({
    required this.profile,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileHeader(
          photoUrl: profile.photoUrl,
          name: profile.name ?? 'No Name',
          email: profile.email ?? '',
          username: profile.username ?? '',
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.01),
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.07, top: screenHeight * 0.01, right: screenWidth * 0.07),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Hi, ${profile.name ?? 'No Name'}!!!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.06),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _SettingsOptionsList(
                    onLogout: () async {
                      await ProfileApi().logout(context);
                    },
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String email;
  final String username;
  final double screenWidth;
  final double screenHeight;

  const _ProfileHeader({
    required this.photoUrl,
    required this.name,
    required this.email,
    required this.username,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth,
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.035),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(screenWidth * 0.1),
          bottomRight: Radius.circular(screenWidth * 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (photoUrl != null) ...[
            _ProfilePhoto(
              photoUrl: photoUrl!,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
            SizedBox(height: screenHeight * 0.018),
          ],
          Text(
            email,
            style: TextStyle(
              fontSize: screenWidth * 0.042,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.004),
          Text(
            'Username: $username',
            style: TextStyle(
              fontSize: screenWidth * 0.037,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsOptionsList extends StatelessWidget {
  final VoidCallback onLogout;
  final double screenWidth;
  final double screenHeight;

  const _SettingsOptionsList({
    required this.onLogout,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.01,
        vertical: screenHeight * 0.01,
      ),
      children: [
        _buildOptionTile(
          context,
          Icons.edit,
          'Edit Profile Name',
          () => print('Edit Profile Name pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.list_alt,
          'List project',
          () => print('List project pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.lock,
          'Change Password',
          () => print('Change Password pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.email,
          'Change Email Address',
          () => print('Change Email Address pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.settings,
          'Settings',
          () => print('Settings pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.tune,
          'Preferences',
          () => print('Preferences pressed'),
        ),
        _buildOptionTile(
          context,
          Icons.logout,
          'Logout',
          onLogout,
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
    {bool isLogout = false,
    }
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: isLogout ? Colors.red : Colors.deepPurple[400]),
          title: Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: isLogout ? Colors.red : Colors.black,
            ),
          ),
          trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
          onTap: onTap,
        ),
        Divider(height: 1, color: Colors.grey[300]),
      ],
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final String photoUrl;
  final double screenWidth;
  final double screenHeight;

  const _ProfilePhoto({
    required this.photoUrl,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final photoSize = screenWidth * 0.3; // Make photo size 30% of screen width
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: photoSize,
          height: photoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.inversePrimary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple[400]!,
                blurRadius: 15,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        Container(
          width: photoSize * 0.925, // Slightly smaller for the inner circle
          height: photoSize * 0.925,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
