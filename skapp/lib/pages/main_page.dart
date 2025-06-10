import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/components/bottomNavbar.dart';
import 'package:skapp/pages/groups.dart';
import 'package:skapp/pages/friends/freinds.dart';
import 'package:skapp/pages/activity.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';

class MainPage extends StatefulWidget {
  final int? initialIndex;

  const MainPage({super.key, this.initialIndex});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Map<String, dynamic> pages;
  late int _selectedIndex;
  late final PageController _pageController;
  bool _isFriendsListEmpty = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 1; // Use provided index or default to Friends
    _pageController = PageController(initialPage: _selectedIndex);

    // Defer loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load profile data
      await ProfileApi().loadAllProfileData(context, forceRefresh: true);
      
      // Initialize alerts
      if (context.mounted) {
        final alertService = Provider.of<AlertService>(context, listen: false);
        final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
        
        // Load pending friend requests which will populate alerts
        await friendsProvider.loadPendingRequests(context);
        
        // You can add other types of alerts initialization here
        // For example: group invitations, activity notifications, etc.
      }
    });

    // Initialize pages map here where we have access to _scaffoldKey
    pages = {
      'Groups': {
        'page': const GroupsPage(),
        'icon': Icons.group,
      },
      'Friends': {
        'page': FreindsPage(
          key: FreindsPage.freindsKey,
          scaffoldKey: _scaffoldKey,
          pageController: _pageController,
          onFriendsListStateChanged: (hasFriends) {
            setState(() {
              _isFriendsListEmpty = !hasFriends;
            });
          },
        ),
        'icon': Icons.person,
      },
      'Activity': {
        'page': const ActivityPage(),
        'icon': Icons.local_activity,
      },
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    if ((_selectedIndex - index).abs() == 1) {
      // Animate for adjacent pages
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Jump for non-adjacent pages
      _pageController.jumpToPage(index);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedIndex == 1 && !_isFriendsListEmpty
          ? CustomAppBar(
              scaffoldKey: _scaffoldKey,
              pageController: _pageController,
              is_bottom_needed: true,
            )
          : CustomAppBar(
              scaffoldKey: _scaffoldKey,
              pageController: _pageController,
            ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
        labels: pages.keys.toList(),
        icons: pages.values.map((page) => page['icon'] as IconData).toList(),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: pages.values.map((page) => page['page'] as Widget).toList(),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
        labels: pages.keys.toList(),
        icons: pages.values.map((page) => page['icon'] as IconData).toList(),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/components/bottomNavbar.dart';
import 'package:skapp/pages/groups.dart';
import 'package:skapp/pages/freinds.dart';
import 'package:skapp/pages/activity.dart';

class MainPage extends StatefulWidget {
  final int? initialIndex;

  const MainPage({super.key, this.initialIndex});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Map<String, dynamic> pages;
  late int _selectedIndex;
  late final PageController _pageController;
  bool _isFriendsListEmpty = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 1; // Use provided index or default to Friends
    _pageController = PageController(initialPage: _selectedIndex);

    // Initialize pages map here where we have access to _scaffoldKey
    pages = {
      'Groups': {
        'page': const GroupsPage(),
        'icon': Icons.group,
      },
      'Friends': {
        'page': FreindsPage(
          scaffoldKey: _scaffoldKey,
          pageController: _pageController,
          onFriendsListStateChanged: (hasFriends) {
            setState(() {
              _isFriendsListEmpty = !hasFriends;
            });
          },
        ),
        'icon': Icons.person,
      },
      'Activity': {
        'page': const ActivityPage(),
        'icon': Icons.local_activity,
      },
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    if ((_selectedIndex - index).abs() == 1) {
      // Animate for adjacent pages
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Jump for non-adjacent pages
      _pageController.jumpToPage(index);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedIndex == 1 && !_isFriendsListEmpty
          ? CustomAppBar(
        scaffoldKey: _scaffoldKey,
        pageController: _pageController,
        page_color_white: true,
      )
          : CustomAppBar(
        scaffoldKey: _scaffoldKey,
        pageController: _pageController,
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
        labels: pages.keys.toList(),
        icons: pages.values.map((page) => page['icon'] as IconData).toList(),
      ),
      // Remove bottomNavigationBar and use Stack instead
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: pages.values.map((page) => page['page'] as Widget).toList(),
          ),
          // Positioned Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
              labels: pages.keys.toList(),
              icons: pages.values.map((page) => page['icon'] as IconData).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
*/