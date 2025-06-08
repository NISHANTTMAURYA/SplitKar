import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:skapp/widgets/custom_loader.dart';

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

  late ProfileApi _profileApi;

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await _profileApi.loadAllProfileData(context);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScreenHeight = MediaQuery.of(context).size.height;
    final ScreenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
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
      body: _buildBody(ScreenWidth, ScreenHeight),
    );
  }

  Widget _buildBody(double screenWidth, double screenHeight) {
    if (_profileApi.isLoading) {
      return CustomLoader();
    }

    if (_profileApi.error != null) {
      return _ErrorDisplay(
        error: _profileApi.error!,
        onRetry: _loadProfileData,
      );
    }

    return _ProfileContent(
      profileApi: _profileApi,
      onLogout: () => _profileApi.logout(context),
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileApi profileApi;
  final VoidCallback onLogout;
  final double screenWidth;
  final double screenHeight;
  
  const _ProfileContent({
    required this.profileApi,
    required this.onLogout,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ProfileHeader(
            photoUrl: profileApi.photoUrl,
            name: profileApi.name ?? 'No Name',
            email: profileApi.email ?? '',
            username: profileApi.profileDetails?['username'] ?? '',
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.03),
          _SettingsOptionsList(
            onLogout: onLogout,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(screenWidth * 0.1),
          bottomRight: Radius.circular(screenWidth * 0.1),
        ),
      ),
      child: Column(
        children: [
          if (photoUrl != null) ...[
            _ProfilePhoto(
              photoUrl: photoUrl!,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
          Text(
            'Hi, ' + name,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            username,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
            ),
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
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
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
      ),
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
                color: Colors.deepPurple,
                blurRadius: 15,
                spreadRadius: 5,
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

class _ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorDisplay({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
            error,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
            onPressed: onRetry,
                    child: Text('Retry'),
                  ),
                ],
            ),
    );
  }
}
