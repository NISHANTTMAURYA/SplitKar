import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/components/appbar.dart';

class FreindsPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;

  const FreindsPage({
    super.key,
    required this.scaffoldKey,
    this.pageController,
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
    final bool hasFriends = friends.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: hasFriends
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: iconSize,
                color: Theme.of(context).colorScheme.inversePrimary,
                semanticLabel: 'Add Friends',
              ),
              Text(
                'Add Friends',
                style: textStyle ?? TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
        SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            return Card(
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
            );
          }, childCount: friends.length),
        ),
        SliverFillRemaining(),
      ],
    );
  }
}

/*
Stack(
      children: [
        // Background: faded image and text
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.08),
            FreindsPage.friendsImage(context, opacity: 0.25),
            SizedBox(height: 20),
            FreindsPage.friendsText(context),
          ],
        ),
        // Foreground: Friends list with header and Add Friends button
        Positioned.fill(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Friends',
                      style: GoogleFonts.cabin(
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FreindsPage.addFriendsButton(
                      context,
                      () {},
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      iconSize: MediaQuery.of(context).size.width * 0.045,
                    ),
                  ],
                ),
              ),
              // Friends list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 20),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white.withOpacity(0.85),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                          child: Text(friends[index][0]),
                        ),
                        title: Text(
                          friends[index],
                          style: GoogleFonts.cabin(fontSize: MediaQuery.of(context).size.width * 0.045),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    )
*/

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
    // Gap grows from 32 to 120 as you scroll (over 30px scroll)
    final double gap = 32 + (shrinkOffset * (120 - 32) / 30).clamp(0, 88);
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
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Friends',
                    style: headerTextStyle,
                  ),
                  SizedBox(width: gap),
                  FreindsPage.addFriendsButton(
                    context,
                    () {},
                    textStyle: headerTextStyle.copyWith(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    iconSize: buttonIconSize,
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
  double get maxExtent => 200.0;

  @override
  double get minExtent => 200.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
