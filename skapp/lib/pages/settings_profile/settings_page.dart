import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:provider/provider.dart';
import 'package:skapp/main.dart'; // For ProfileNotifier
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/pages/settings_profile/edit_profile_page.dart';

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
    if (profile.error != null && profile.error!.isNotEmpty) {
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ProfileApi().loadAllProfileData(context, forceRefresh: true);
        },
        child: _ProfileContent(
          profile: profile,
          screenWidth: ScreenWidth,
          screenHeight: ScreenHeight,
        ),
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
    return ListView(
      physics: AlwaysScrollableScrollPhysics(), // Enable scrolling even when content is small
      children: [
        _ProfileHeader(
          photoUrl: profile.photoUrl,
          name: profile.name ?? 'No Name',
          email: profile.email ?? '',
          username: profile.username ?? '',
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
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
          if (photoUrl != null && photoUrl!.isNotEmpty) ...[
            _ProfilePhoto(
              photoUrl: photoUrl!,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
            SizedBox(height: screenHeight * 0.018),
          ] else ...[
            // Show default avatar if no photo URL
            Container(
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: screenWidth * 0.15,
                color: Colors.grey[600],
              ),
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
  final Logger _logger = Logger('_SettingsOptionsList');

  _SettingsOptionsList({
    required this.onLogout,
    required this.screenWidth,
    required this.screenHeight,
  });

  void _navigateWithAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

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
          () {
            _logger.info('Navigating to Edit Profile page');
            _navigateWithAnimation(context, EditProfilePage());
          },
        ),
        _buildOptionTile(
          context,
          Icons.list_alt,
          'List project',
          () {
            _logger.info('List project option pressed');
            // TODO: Implement list project functionality
          },
        ),
        _buildOptionTile(
          context,
          Icons.lock,
          'Change Password',
          () {
            _logger.info('Change Password option pressed');
            // TODO: Implement change password functionality
          },
        ),
        _buildOptionTile(
          context,
          Icons.email,
          'Change Email Address',
          () {
            _logger.info('Change Email Address option pressed');
            // TODO: Implement change email functionality
          },
        ),
        _buildOptionTile(
          context,
          Icons.settings,
          'Settings',
          () {
            _logger.info('Settings option pressed');
            // TODO: Implement settings functionality
          },
        ),
        _buildOptionTile(
          context,
          Icons.tune,
          'Preferences',
          () {
            _logger.info('Preferences option pressed');
            // TODO: Implement preferences functionality
          },
        ),
        _buildOptionTile(
          context,
          Icons.logout,
          'Logout',
          () {
            _logger.info('Logout option pressed');
            onLogout();
          },
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
  final _logger = Logger('_ProfilePhoto');

  _ProfilePhoto({
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
            color: Colors.white,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CustomLoader(
                  size: photoSize * 0.3,
                  isButtonLoader: true,
                ),
              ),
              errorWidget: (context, url, error) {
                _logger.warning('Failed to load profile image: $error');
                return Icon(
                  Icons.person,
                  size: photoSize * 0.4,
                  color: Colors.grey[400],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
