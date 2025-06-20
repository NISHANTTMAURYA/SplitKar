import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/pages/groups/group_service.dart';
import 'package:skapp/pages/groups/group_provider.dart';
// import 'package:skapp/pages/groups/friends_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/main.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/pages/groups/add_group_sheet.dart';
// import 'package:skapp/pages/groups/friends_provider.dart';
import 'package:skapp/components/alerts/alert_service.dart';
import 'package:skapp/pages/screens/group_chat_screen.dart';
import 'package:skapp/pages/screens/group_chat_screen.dart';
import 'package:skapp/components/anim_search_bar.dart';

class GroupsPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Function(bool) onFriendsListStateChanged;
  final ScrollController? scrollController;

  // Add a global key for the state
  static final GlobalKey<_GroupsPageState> freindsKey =
      GlobalKey<_GroupsPageState>();

  // Define reusable text style
  static TextStyle _getBaseTextStyle(double baseSize) =>
      GoogleFonts.cabin(fontSize: baseSize * 0.035);

  const GroupsPage({
    super.key,
    required this.scaffoldKey,
    this.pageController,
    required this.onFriendsListStateChanged,
    this.scrollController,
  });

  @override
  State<GroupsPage> createState() => _GroupsPageState();

  // Add static method to refresh groups
  static Future<void> refreshGroups() async {
    // Use provider directly instead of state
    final context = freindsKey.currentContext;
    if (context != null) {
      await Provider.of<GroupProvider>(
        context,
        listen: false,
      ).loadGroups(forceRefresh: true);
    }
  }

  static Widget friendsImage(BuildContext context, {double? opacity}) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Center(
      child: Opacity(
        opacity: opacity ?? 1.0,
        child: Image.asset(
          'assets/images/freinds.png',
          width: width * 0.9,
          height: height * 0.4,
        ),
      ),
    );
  }

  // Shared widget for the groups text
  static Widget friendsText(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final double baseSize = width < height ? width : height;
    return Center(
      child: Text(
        'Kharcha share karo, dosti save karo!',
        style: _getBaseTextStyle(baseSize),
      ),
    );
  }

  // Shared widget for the Make a Group button
  static Widget addGroupsButton(
    BuildContext context,
    VoidCallback onAddFriends, {
    TextStyle? textStyle,
    double? iconSize,
    required double width,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(width * 0.03),
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.grey.withOpacity(0.3),
        highlightColor: Colors.deepPurple.withOpacity(0.1),
        onTap: () async {
          final bool shouldRefresh = await AddFriendsSheet.show(context);
          if (shouldRefresh && context.mounted) {
            // Refresh groups using provider
            await Provider.of<GroupProvider>(
              context,
              listen: false,
            ).loadGroups(forceRefresh: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: iconSize,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    semanticLabel: 'Make a Group',
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Make a Group',
                      style:
                          textStyle ??
                          TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.w800,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GroupsPageState extends State<GroupsPage> {
  Future<void> refreshAll() async {
    if (mounted) {
      await context.read<GroupProvider>().loadGroups(forceRefresh: true);
      if (context.mounted) {
        final alertService = Provider.of<AlertService>(context, listen: false);
        await alertService.fetchAlerts(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load groups through provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GroupProvider>().loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(body: CustomLoader());
        }

        if (provider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: MediaQuery.of(context).size.width * 0.12,
                    color: Colors.red,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () => provider.loadGroups(forceRefresh: true),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: refreshAll,
            child: provider.groups.isNotEmpty
                ? _GroupsListView(
                    scaffoldKey: widget.scaffoldKey,
                    pageController: widget.pageController,
                    onRefresh: refreshAll,
                    scrollController: widget.scrollController,
                  )
                : _NoGroupsView(onAddFriends: () {}),
          ),
        );
      },
    );
  }
}

class _NoGroupsView extends StatefulWidget {
  final VoidCallback onAddFriends;

  const _NoGroupsView({required this.onAddFriends});

  @override
  State<_NoGroupsView> createState() => _NoFriendsViewState();
}

class _NoFriendsViewState extends State<_NoGroupsView> {
  TextStyle _getGreetingStyle(double width) => GoogleFonts.cabin(
    fontSize: width * 0.055, // Slightly smaller to handle long usernames better
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.deepPurple[400]),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04, // Responsive padding
              vertical: width * 0.03,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Heyyloo, ${context.watch<ProfileNotifier>().username ?? 'User'} !!',
                      style: _getGreetingStyle(width),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: width * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GroupsPage.friendsImage(context),
                SizedBox(height: width * 0.05),
                GroupsPage.friendsText(context),
                SizedBox(height: width * 0.04),
                GroupsPage.addGroupsButton(
                  context,
                  widget.onAddFriends,
                  textStyle: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  iconSize: width * 0.05,
                  width: width,
                ),
                SizedBox(height: width * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupsListView extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;

  const _GroupsListView({
    required this.scaffoldKey,
    required this.onRefresh,
    this.pageController,
    this.scrollController,
  });

  @override
  State<_GroupsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<_GroupsListView> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  bool isSearchOpen = false;
  final TextEditingController textController = TextEditingController();
  String _searchQuery = '';

  // Define reusable text styles
  TextStyle _getFriendNameStyle(double width) =>
      GoogleFonts.cabin(fontSize: width * 0.045);

  TextStyle _getHeaderStyle(double width) =>
      GoogleFonts.cabin(fontSize: width * 0.08, fontWeight: FontWeight.bold);

  TextStyle _getGreetingStyle(double width) =>
      GoogleFonts.cabin(fontSize: width * 0.07, fontWeight: FontWeight.w600);

  TextStyle _getFriendCountStyle(bool isBold, double width) =>
      GoogleFonts.cabin(
        fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        fontSize: isBold ? width * 0.04 : width * 0.035,
        color: Colors.deepPurple,
        letterSpacing: isBold ? 0.5 : 0.2,
        shadows: [
          Shadow(
            color: Colors.deepPurple.withOpacity(isBold ? 0.15 : 0.10),
            blurRadius: isBold ? 2 : 1,
            offset: Offset(0.5, 1),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);
    textController.addListener(_onSearchChanged);
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = textController.text;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    textController.removeListener(_onSearchChanged);
    textController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final groupProvider = context.watch<GroupProvider>();
    final filteredGroups = groupProvider.filteredGroups(_searchQuery);

    final double height = MediaQuery.of(context).size.height;
    final double baseSize = width < height ? width : height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Get the styles for this build context
    final groupNameStyle = _getFriendNameStyle(width);
    final headerTextStyle = _getHeaderStyle(width);
    final greetingStyle = _getGreetingStyle(width);
    final friendCountRegularStyle = _getFriendCountStyle(false, width);
    final friendCountBoldStyle = _getFriendCountStyle(true, width);

    final double buttonFontSize = width * 0.04;
    final double buttonIconSize = width * 0.05;


    // Get groups from provider and filter them
    final groups = context.watch<GroupProvider>().groups;


    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Image Header
          SliverPersistentHeader(
            pinned: false,
            floating: true,
            delegate: _ImageHeaderDelegate(
              statusBarHeight: statusBarHeight,
              scrollOffset: _scrollOffset,
              screenHeight: height,
            ),
          ),
          // Purple container with animation
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: height * 0.075,
            toolbarHeight: height * 0.075,
            backgroundColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                return _FriendsHeaderDelegate(
                  context,
                  headerTextStyle: headerTextStyle,
                  buttonFontSize: buttonFontSize,
                  buttonIconSize: buttonIconSize,
                  scrollOffset: _scrollOffset,
                  screenWidth: width,
                  screenHeight: height,
                ).build(
                  context,
                  constraints.maxHeight - constraints.minHeight,
                  constraints.maxHeight != constraints.minHeight,
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: height * 0.007)),
          SliverAppBar(
            snap: true,
            floating: true,
            expandedHeight: height * 0.08,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, // Match list item padding
                  vertical: height * 0.012,
                ),
                child: Row(
                  children: [
                    // Search Bar
                    Container(
                      height: height * 0.055, // More responsive height
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 1.1,
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: width * 0.01),
                          child: AnimSearchBar(
                            width: isSearchOpen
                                ? (width * 0.92 - (width * 0.04 * 2) - width * 0.02)
                                : width * 0.13,
                            textController: textController,
                            onSuffixTap: () {
                              setState(() {
                                textController.clear();
                                isSearchOpen = false;
                              });
                            },
                            onSubmitted: (String value) {
                              setState(() {
                                isSearchOpen = false;
                              });
                            },
                            onToggle: (bool value) {
                              setState(() {
                                isSearchOpen = value;
                              });
                            },
                            autoFocus: true,
                            closeSearchOnSuffixTap: true,
                            color: Colors.white,
                            textFieldColor: Colors.white,
                            searchIconColor: Colors.deepPurple,
                            textFieldIconColor: Colors.deepPurple,
                            helpText: "Search groups...",
                            style: TextStyle(
                              fontSize: width * 0.04,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.08), // Match list spacing
                    // Greeting Text
                    Expanded(
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: isSearchOpen ? 0.0 : 1.0,
                        child: Text(
                          'Heyyloo, ${context.watch<ProfileNotifier>().username ?? 'User'} !!',
                          style: greetingStyle.copyWith(
                             // Responsive font size
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: height * 0.007)),
          SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final group = filteredGroups[index];
              final double avatarSize = width * 0.12;
              final double imageSize = width * 0.13;

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/group-chat',
                    arguments: {
                      'chatName': group['name']?.toString() ?? 'Group Chat',
                      'chatImageUrl': group['profile_picture_url'],
                      'groupId': group['id'],
                    },
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.01,
                  ),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.04),
                    ),
                    margin: EdgeInsets.symmetric(vertical: width * 0.01),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: width * 0.015,
                      ),
                      leading: CircleAvatar(
                        radius: avatarSize / 2.2,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withOpacity(0.7),
                        child: ClipOval(
                          child:
                              (group['profile_picture_url'] != null &&
                                  (group['profile_picture_url'] as String)
                                      .isNotEmpty &&
                                  (group['profile_picture_url'] as String)
                                      .startsWith('http'))
                              ? CachedNetworkImage(
                                  imageUrl: group['profile_picture_url'],
                                  placeholder: (context, url) => CustomLoader(
                                    size: avatarSize * 0.6,
                                    isButtonLoader: true,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.groups_2_outlined,
                                    size: avatarSize * 0.6,
                                  ),
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.groups_2_outlined,
                                  size: avatarSize * 0.6,
                                ),
                        ),
                      ),
                      title: Text(
                        group['name']?.toString() ?? 'Group Name not fetched',
                        style: _getFriendNameStyle(width),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: filteredGroups.length),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.width * 0.03,
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.035,
                    vertical: MediaQuery.of(context).size.width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.025,
                    ),
                    border: Border.all(color: Colors.deepPurple, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.08),
                        blurRadius: 4,
                        offset: Offset(0.5, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You have ',
                        style: _getFriendCountStyle(false, width),
                      ),
                      Text(
                        '${groups.length}',
                        style: _getFriendCountStyle(true, width),
                      ),
                      Text(
                        ' groups 🎉',
                        style: _getFriendCountStyle(false, width),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 70 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final BuildContext context;
  final TextStyle headerTextStyle;
  final double buttonFontSize;
  final double buttonIconSize;
  final double scrollOffset;
  final double screenWidth;
  final double screenHeight;

  const _FriendsHeaderDelegate(
    this.context, {
    required this.headerTextStyle,
    required this.buttonFontSize,
    required this.buttonIconSize,
    required this.scrollOffset,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Calculate gap based on overall scroll position with increased range
    final double rawGap =
        16 + (scrollOffset * (170 - 16) / 300); // Increased from 160 to 300
    final double clampedGap = rawGap.clamp(16.0, 140.0); // Increased max gap
    final double easedGap =
        clampedGap * (1 - (clampedGap / 300) * 0.3); // Adjusted easing

    return Container(
      decoration: BoxDecoration(color: Colors.deepPurple[400]),
      child: SizedBox(
        height: maxExtent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Groups',
                      style: headerTextStyle.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: easedGap),
                  Flexible(
                    child: GroupsPage.addGroupsButton(
                      context,
                      () {},
                      textStyle: headerTextStyle.copyWith(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      iconSize: buttonIconSize,
                      width: screenWidth,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => screenHeight * 0.075;

  @override
  double get minExtent => screenHeight * 0.075;

  @override
  bool shouldRebuild(covariant _FriendsHeaderDelegate oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.screenHeight != screenHeight;
  }
}

class _ImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double scrollOffset;
  final double screenHeight;

  const _ImageHeaderDelegate({
    required this.statusBarHeight,
    required this.scrollOffset,
    required this.screenHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double visibleHeight = maxExtent - shrinkOffset;

    return Container(
      height: visibleHeight,
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            height: maxExtent,
            child: Image.asset('assets/images/groups.png', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => screenHeight * 0.25 + statusBarHeight;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant _ImageHeaderDelegate oldDelegate) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.screenHeight != screenHeight;
  }
}
