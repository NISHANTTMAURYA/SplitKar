import 'package:flutter/material.dart' hide ScrollDirection;
import 'package:flutter/material.dart' show ScrollDirection;
import 'package:skapp/components/appbar.dart';
import 'package:skapp/components/drawer.dart';
import 'package:skapp/components/bottomNavbar.dart';
import 'package:skapp/pages/groups/groups.dart';
import 'package:skapp/pages/friends/freinds.dart';
import 'package:skapp/pages/activity.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:skapp/components/alerts/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:skapp/pages/groups/group_provider.dart';

class MainPage extends StatefulWidget {
  final int? initialIndex;

  const MainPage({super.key, this.initialIndex});

  static final GlobalKey<MainPageState> mainPageKey = GlobalKey<MainPageState>();

  // Add static method to refresh data
  static Future<void> refreshData(BuildContext context) async {
    final state = mainPageKey.currentState;
    if (state != null && state.mounted) {
      await state.refreshData();
    }
  }

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Map<String, dynamic> pages;
  late int _selectedIndex;
  late final PageController _pageController;
  bool _isFriendsListEmpty = true;
  bool _isBottomBarVisible = true;
  final ScrollController _scrollController = ScrollController();
  double _previousScrollPosition = 0;
  double _lastScrollUpdateTime = 0;

  // Add method to refresh data
  Future<void> refreshData() async {
    if (mounted) {
      // Refresh friends list
      if (FreindsPage.freindsKey.currentState != null) {
        await FreindsPage.freindsKey.currentState!.refreshFriends();
      }
      
      // Refresh groups list using static method
      await GroupsPage.refreshGroups();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 1;
    _pageController = PageController(initialPage: _selectedIndex);

    // Add scroll listener
    _scrollController.addListener(_handleScroll);

    // Initialize pages map here where we have access to _scaffoldKey
    pages = {
      'Groups': {
        'page': GroupsPage(
          key: GroupsPage.freindsKey,
          scaffoldKey: _scaffoldKey,
          pageController: _pageController,
          scrollController: _scrollController,
          onFriendsListStateChanged: (hasFriends) {
            if (!mounted) return;
            setState(() {
              _isFriendsListEmpty = !hasFriends;
            });
          },
        ),
        'icon': Icons.group,
      },
      'Friends': {
        'page': FreindsPage(
          key: FreindsPage.freindsKey,
          scaffoldKey: _scaffoldKey,
          pageController: _pageController,
          scrollController: _scrollController,
          onFriendsListStateChanged: (hasFriends) {
            if (!mounted) return;
            setState(() {
              _isFriendsListEmpty = !hasFriends;
            });
          },
        ),
        'icon': Icons.person,
      },
      'Activity': {
        'page': ActivityPage(scrollController: _scrollController),
        'icon': Icons.local_activity,
      },
    };

    // Defer loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      // Start both operations in parallel
      final profileFuture = ProfileApi().loadAllProfileData(context, forceRefresh: true);
      final alertService = Provider.of<AlertService>(context, listen: false);
      final alertsFuture = alertService.fetchAlerts(context);

      // Wait for both to complete (optional)
      await Future.wait([profileFuture, alertsFuture]);
    });
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    final currentPosition = _scrollController.position.pixels;
    final scrollDelta = currentPosition - _previousScrollPosition;
    final timeDelta = currentTime - _lastScrollUpdateTime;
    
    // Calculate scroll velocity (pixels per millisecond)
    final scrollVelocity = timeDelta > 0 ? scrollDelta / timeDelta : 0;
    
    // Adjust thresholds based on velocity
    final isScrollingDown = scrollDelta > 0;
    final isScrollingUp = scrollDelta < 0;
    
    // Show/hide based on scroll direction and current state
    if (isScrollingDown && _isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = false;
      });
    } else if (isScrollingUp && !_isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = true;
      });
    }
    
    // Update previous values
    _previousScrollPosition = currentPosition;
    _lastScrollUpdateTime = currentTime;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    setState(() {
      _isBottomBarVisible = true;  // Show bottom bar when switching pages
    });
    
    if ((_selectedIndex - index).abs() == 1) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
      body: Stack(
        children: [
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
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isBottomBarVisible ? 1 : 0,
          child: BottomNavbar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            labels: pages.keys.toList(),
            icons: pages.values.map((page) => page['icon'] as IconData).toList(),
          ),
        ),
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