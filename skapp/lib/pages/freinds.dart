import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/components/appbar.dart';

class FreindsPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final Function(bool) onFriendsListStateChanged;

  const FreindsPage({
    super.key,
    required this.scaffoldKey,
    this.pageController,
    required this.onFriendsListStateChanged,
  });

  // Example dynamic friends list (replace with your data source)
  final List<String> friends = const [
    "chaitu",
    "nishant",
    "arjun",
    "meera",
    "sana",
    "rahul",
    "zoya",
    "amit",
    "krish",
    "riya",
    "neha",
    "kabir",
    "tanvi",
    "manav",
    "isha",
    "rohan",
  ];
  

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final bool hasFriends = friends.isNotEmpty;
    
    // Add this line to print the color
    print('Inverse Primary Color: ${Theme.of(context).colorScheme.inversePrimary}');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onFriendsListStateChanged(hasFriends);
    });
    
    return Scaffold(
      body: hasFriends
              ? _FriendsListView(
                  friends: friends,
                  scaffoldKey: scaffoldKey,
                  pageController: pageController,
                )
              : _NoFriendsView(
                  onAddFriends: () {
                    /* TODO: Add friends logic */
                  },
                ),
        
    );
  }

  // Shared widget for the friends image
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
        style: GoogleFonts.cabin(fontSize: baseSize * 0.035),
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
        onTap: onAddFriends,
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
                      style: textStyle ?? TextStyle(
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

class _NoFriendsView extends StatelessWidget {
  final VoidCallback onAddFriends;
  const _NoFriendsView({required this.onAddFriends});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.08),
        FreindsPage.friendsImage(context),
        SizedBox(height: 20),
        FreindsPage.friendsText(context),
        SizedBox(height: 15),
        FreindsPage.addFriendsButton(context, onAddFriends),
      ],
    );
  }
}

class _FriendsListView extends StatelessWidget {
  final List<String> friends;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
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
    final TextStyle friendNameStyle = GoogleFonts.cabin(
      fontSize: width * 0.045,
    );
    final TextStyle headerTextStyle = GoogleFonts.cabin(
      fontSize: width * 0.08,
      fontWeight: FontWeight.bold,
    );
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
      child: SizedBox(height: 10), // <-- This adds vertical space (16 pixels)
    ),
        SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8,0,8,0),
              child: Card(
                color: Colors.white.withOpacity(0.85),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withOpacity(0.7),
                    child: Text(friends[index][0]),
                  ),
                  title: Text(
                    friends[index],
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 1,
                  ),
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
                      style: GoogleFonts.cabin(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.deepPurple,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.deepPurple.withOpacity(0.10),
                            blurRadius: 1,
                            offset: Offset(0.5, 1),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${friends.length}',
                      style: GoogleFonts.cabin(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.deepPurple.withOpacity(0.15),
                            blurRadius: 2,
                            offset: Offset(0.5, 1),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ' friends 🎉',
                      style: GoogleFonts.cabin(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.deepPurple,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.deepPurple.withOpacity(0.10),
                            blurRadius: 1,
                            offset: Offset(0.5, 1),
                          ),
                        ],
                      ),
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
