import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/pages/friends/friends_service.dart';
import 'package:skapp/pages/friends/friends_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/main.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/pages/friends/add_friends_sheet.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:skapp/services/alert_service.dart';

class FreindsPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Function(bool) onFriendsListStateChanged;

  // Add a global key for the state
  static final GlobalKey<_FreindsPageState> freindsKey =
      GlobalKey<_FreindsPageState>();

  // Define reusable text style
  static TextStyle _getBaseTextStyle(double baseSize) =>
      GoogleFonts.cabin(fontSize: baseSize * 0.035);

  const FreindsPage({
    super.key,
    required this.scaffoldKey,
    this.pageController,
    required this.onFriendsListStateChanged,
  });

  @override
  State<FreindsPage> createState() => _FreindsPageState();

  // Add a static method to reload friends
  static Future<void> reloadFriends() async {
    final context = freindsKey.currentContext;
    if (context != null) {
      final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
      await friendsProvider.refreshFriends();
      if (context.mounted) {
        final alertService = Provider.of<AlertService>(context, listen: false);
        await alertService.fetchAlerts(context);
      }
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

  // Shared widget for the friends text
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

  // Shared widget for the add friends button
  static Widget addFriendsButton(
    BuildContext context,
    VoidCallback onAddFriends, {
    TextStyle? textStyle,
    double? iconSize,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.grey.withOpacity(0.3),
        highlightColor: Colors.deepPurple.withOpacity(0.1),
        onTap: () {
          showModalBottomSheet(
            barrierColor: Colors.deepPurple[400],
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, controller) => ChangeNotifierProvider(
                create: (_) => FriendsProvider(),
                child: const AddFriendsSheet(),
              ),
            ),
          );
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
                    semanticLabel: 'Add Friends',
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Add Friends',
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

class _FreindsPageState extends State<FreindsPage> {
  final FriendsService _friendsService = FriendsService();

  Future<void> refreshFriends() async {
    await refreshAll();
  }

  Future<void> refreshAll() async {
    if (mounted) {
      await context.read<FriendsProvider>().refreshFriends();
      if (context.mounted) {
        final alertService = Provider.of<AlertService>(context, listen: false);
        await alertService.fetchAlerts(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load friends when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        final width = MediaQuery.of(context).size.width;
        final double height = MediaQuery.of(context).size.height;
        final double baseSize = width < height ? width : height;
        final double statusBarHeight = MediaQuery.of(context).padding.top;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFriendsListStateChanged(friendsProvider.friends.isNotEmpty);
        });

        // Show loader if loading
        if (friendsProvider.isLoading) {
          return Scaffold(body: CustomLoader());
        }

        // Show error if there is one
        if (friendsProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    friendsProvider.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => friendsProvider.refreshFriends(),
                    child: Text('Retry')
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: refreshAll,
            child: friendsProvider.friends.isNotEmpty
                ? _FriendsListView(
                    friends: friendsProvider.friends,
                    scaffoldKey: widget.scaffoldKey,
                    pageController: widget.pageController,
                    onRefresh: refreshAll,
                  )
                : _NoFriendsView(onAddFriends: () {}),
          ),
        );
      },
    );
  }
}

class _NoFriendsView extends StatefulWidget {
  final VoidCallback onAddFriends;

  const _NoFriendsView({required this.onAddFriends});

  @override
  State<_NoFriendsView> createState() => _NoFriendsViewState();
}

class _NoFriendsViewState extends State<_NoFriendsView> {
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
                FreindsPage.friendsImage(context),
                SizedBox(height: width * 0.05),
                FreindsPage.friendsText(context),
                SizedBox(height: width * 0.04),
                FreindsPage.addFriendsButton(context, widget.onAddFriends),
                SizedBox(height: width * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsListView extends StatefulWidget {
  final List<dynamic> friends;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Future<void> Function() onRefresh;

  const _FriendsListView({
    required this.friends,
    required this.scaffoldKey,
    required this.onRefresh,
    this.pageController,
  });

  @override
  State<_FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<_FriendsListView> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

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
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final double baseSize = width < height ? width : height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Get the styles for this build context
    final friendNameStyle = _getFriendNameStyle(width);
    final headerTextStyle = _getHeaderStyle(width);
    final greetingStyle = _getGreetingStyle(width);
    final friendCountRegularStyle = _getFriendCountStyle(false, width);
    final friendCountBoldStyle = _getFriendCountStyle(true, width);

    final double buttonFontSize = width * 0.04;
    final double buttonIconSize = width * 0.05;

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
            ),
          ),
          // Purple container with animation
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 60,
            toolbarHeight: 60,
            backgroundColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                print('Debug - Scroll Values:');
                print('scrollOffset: $_scrollOffset');
      
                return _FriendsHeaderDelegate(
                  context,
                  headerTextStyle: headerTextStyle,
                  buttonFontSize: buttonFontSize,
                  buttonIconSize: buttonIconSize,
                  scrollOffset: _scrollOffset,
                ).build(
                  context,
                  constraints.maxHeight - constraints.minHeight,
                  constraints.maxHeight != constraints.minHeight,
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 5,
            ), // <-- This adds vertical space (16 pixels)
          ),
          SliverAppBar(
            snap: true,
            floating: true,
            expandedHeight: 40,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Heyyloo, ${context.watch<ProfileNotifier>().username ?? 'User'} !!',
                        style: greetingStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      
          SliverToBoxAdapter(
            child: SizedBox(
              height: 5,
            ), // <-- This adds vertical space (16 pixels)
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final double width = MediaQuery.of(context).size.width;
              final double avatarSize = width * 0.12; // Responsive avatar size
              final double imageSize =
                  width * 0.13; // Slightly larger for the image
      
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, // 2.5% of screen width
                  vertical: width * 0.01, // 1.5% of screen width
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      width * 0.04,
                    ), // Responsive border radius
                  ),
                  margin: EdgeInsets.symmetric(vertical: width * 0.01),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: width * 0.015,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/screen',
                        arguments: {
                          'chatName': widget.friends[index]['username']?.toString() ?? 'Friend Chat',
                          'chatImageUrl': widget.friends[index]['profile_picture_url'],
                          'isGroupChat': false,
                        },
                      );
                    },
                    leading: CircleAvatar(
                      radius: avatarSize / 2.2,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary.withOpacity(0.7),
                      child: ClipOval(
                        child: (widget.friends[index]['profile_picture_url'] != null &&
                                (widget.friends[index]['profile_picture_url'] as String).isNotEmpty &&
                                (widget.friends[index]['profile_picture_url'] as String).startsWith('http'))
                            ? CachedNetworkImage(
                                imageUrl: widget.friends[index]['profile_picture_url'],
                                placeholder: (context, url) => CustomLoader(
                                  size: avatarSize * 0.6,
                                  isButtonLoader: true,
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.person, size: avatarSize * 0.6),
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.person, size: avatarSize * 0.6),
                      ),
                    ),
                    title: Text(
                      widget.friends[index]['username']?.toString() ?? 'No Name',
                      style: friendNameStyle,
                    ),
                  ),
                ),
              );
            }, childCount: widget.friends.length),
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
                        '${widget.friends.length}',
                        style: _getFriendCountStyle(true, width),
                      ),
                      Text(
                        ' friends 🎉',
                        style: _getFriendCountStyle(false, width),
                      ),
                    ],
                  ),
                ),
              ),
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

  const _FriendsHeaderDelegate(
    this.context, {
    required this.headerTextStyle,
    required this.buttonFontSize,
    required this.buttonIconSize,
    required this.scrollOffset,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    print('Debug - Animation Values:');
    print('scrollOffset: $scrollOffset');

    // Calculate gap based on overall scroll position with increased range
    final double rawGap =
        16 + (scrollOffset * (170 - 16) / 300); // Increased from 160 to 300
    final double clampedGap = rawGap.clamp(16.0, 140.0); // Increased max gap
    final double easedGap =
        clampedGap * (1 - (clampedGap / 300) * 0.3); // Adjusted easing

    print('Debug - Gap Calculation:');
    print('rawGap: $rawGap');
    print('clampedGap: $clampedGap');
    print('easedGap: $easedGap');

    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple[400],

      ),
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
                      'Friends',
                      style: headerTextStyle.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: easedGap),
                  Flexible(
                    child: FreindsPage.addFriendsButton(
                      context,
                      () {},
                      textStyle: headerTextStyle.copyWith(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      iconSize: buttonIconSize,
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
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _FriendsHeaderDelegate oldDelegate) {
    return true;
  }
}

class _ImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double scrollOffset;

  const _ImageHeaderDelegate({
    required this.statusBarHeight,
    required this.scrollOffset,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            height: maxExtent,
            child: Image.asset(
              'assets/images/freinds_scroll.jpg',
              fit: BoxFit.cover,
            ),
          ),


        ],
      ),
    );
  }

  @override
  double get maxExtent => 200 + statusBarHeight;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant _ImageHeaderDelegate oldDelegate) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
