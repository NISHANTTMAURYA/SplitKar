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


class FreindsPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Function(bool) onFriendsListStateChanged;

  // Define reusable text style
  static TextStyle _getBaseTextStyle(double baseSize) => GoogleFonts.cabin(
    fontSize: baseSize * 0.035,
  );

  const FreindsPage({
    super.key,
    required this.scaffoldKey,
    this.pageController,
    required this.onFriendsListStateChanged,
  });

  @override
  State<FreindsPage> createState() => _FreindsPageState();
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
  List<dynamic> _friends = [];
  bool _isLoading = true;
  String? _error;
  final FriendsService _friendsService = FriendsService();

  Future<void> _loadFriends() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final friends = await _friendsService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  bool _isImagePreloaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImagePreloaded) {
      precacheImage(
        const AssetImage('assets/images/freinds_scroll.jpg'),
        context,
      );
      _isImagePreloaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final bool hasFriends = _friends.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFriendsListStateChanged(hasFriends);
    });

    // Show loader if loading
    if (_isLoading) {
      return Scaffold(
        body: CustomLoader(),
      );
    }

    // Show error if there is one
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFriends,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFriends,
        child: hasFriends
            ? _FriendsListView(
                friends: _friends,
                scaffoldKey: widget.scaffoldKey,
                pageController: widget.pageController,
              )
            : _NoFriendsView(onAddFriends: () {}),
      ),
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
    fontSize: width * 0.055,  // Slightly smaller to handle long usernames better
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
            decoration: BoxDecoration(
              color: Colors.deepPurple[400],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,  // Responsive padding
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

class _FriendsListView extends StatelessWidget {
  final List<dynamic> friends;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;

  // Define reusable text styles
  TextStyle _getFriendNameStyle(double width) => GoogleFonts.cabin(
    fontSize: width * 0.045,
  );

  TextStyle _getHeaderStyle(double width) => GoogleFonts.cabin(
    fontSize: width * 0.08,
    fontWeight: FontWeight.bold,
  );

  TextStyle _getGreetingStyle(double width) => GoogleFonts.cabin(
    fontSize: width * 0.07,
    fontWeight: FontWeight.w600,
  );

  TextStyle _getFriendCountStyle(bool isBold) => GoogleFonts.cabin(
    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
    fontSize: isBold ? 16 : 13,
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

  const _FriendsListView({
    required this.friends,
    required this.scaffoldKey,
    this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final double baseSize = width < height ? width : height;
    
    // Get the styles for this build context
    final friendNameStyle = _getFriendNameStyle(width);
    final headerTextStyle = _getHeaderStyle(width);
    final greetingStyle = _getGreetingStyle(width);
    final friendCountRegularStyle = _getFriendCountStyle(false);
    final friendCountBoldStyle = _getFriendCountStyle(true);

    final double buttonFontSize = width * 0.04;
    final double buttonIconSize = width * 0.05;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          floating: true,
          pinned: false,
          delegate: _FriendsHeaderDelegate(
            context,
            headerTextStyle: headerTextStyle,
            buttonFontSize: buttonFontSize,
            buttonIconSize: buttonIconSize,
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: friends[index]['profile_picture_url'] ?? '',
                        placeholder: (context, url) => CustomLoader(
                          size: 25,
                          isButtonLoader: true,
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.person),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  title: Text(
                    friends[index]['username']?.toString() ?? 'No Name',
                    style: friendNameStyle,
                  ),
                ),
              ),
            );
          }, childCount: friends.length),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.08),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You have ',
                      style: friendCountRegularStyle,
                    ),
                    Text(
                      '${friends.length}',
                      style: friendCountBoldStyle,
                    ),
                    Text(
                      ' friends 🎉',
                      style: friendCountRegularStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final BuildContext context;
  final TextStyle headerTextStyle;
  final double buttonFontSize;
  final double buttonIconSize;

  const _FriendsHeaderDelegate(
    this.context, {
    required this.headerTextStyle,
    required this.buttonFontSize,
    required this.buttonIconSize,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // ANIMATION LOGIC EXPLANATION:
    // 1. Base Gap Calculation:
    //    - Starts at 16px (minimum gap)
    //    - Ends at 160px (maximum gap - increased for more spread)
    //    - Takes 300px of scroll to complete (much slower animation)
    //    - Formula: minGap + (scrollProgress * (maxGap - minGap) / scrollDistance)
    final double gap = 16 + (shrinkOffset * (160 - 16) / 300).clamp(0, 144);

    // 2. Easing Function:
    //    - Creates non-linear animation for natural feel
    //    - As gap approaches max (160px), movement slows down
    //    - 0.4 is the easing factor (higher = stronger easing)
    //    - Formula: gap * (1 - (gap/maxGap) * easingFactor)
    final double easedGap = gap * (1 - (gap / 160) * 0.4);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/freinds_scroll.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SizedBox(
        height: maxExtent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple[400],
                borderRadius: BorderRadius.circular(3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3. Layout Structure:
                      //    - Flexible widgets allow content to shrink if needed
                      //    - SizedBox with easedGap creates the animated spacing
                      //    - Text and button maintain their relative positions
                      Flexible(
                        child: Text(
                          'Friends',
                          style: headerTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: gap),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 200.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
