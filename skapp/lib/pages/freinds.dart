import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FreindsPage extends StatelessWidget {
  const FreindsPage({super.key});

  // Example dynamic friends list (replace with your data source)
  final List<String> friends = const [
  // "chaitu",
  // "nishant",
  // "arjun",
  // "meera",
  // "sana",
  // "rahul",
  // "zoya",
  // "amit",
  // "krish",
  // "riya",
  // "neha",
  // "kabir",
  // "tanvi",
  // "manav",
  // "isha",
  // "rohan",
];


  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final double baseSize = width < height ? width : height;
    final bool hasFriends = friends.isNotEmpty;

    if (!hasFriends) {
      // No friends: image, text, button (in order)
      return Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.08),
              Center(
                child: Image.asset(
                  'assets/images/freinds.png',
                  width: width * 0.9,
                  height: height * 0.4,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Kharcha share karo, dosti save karo!',
                  style: GoogleFonts.cabin(fontSize: baseSize * 0.035),
                ),
              ),
              SizedBox(height: 15),
              Material(
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
                  splashColor: Colors.deepPurple.withOpacity(0.3),
                  highlightColor: Colors.deepPurple.withOpacity(0.1),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: baseSize * 0.07,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          semanticLabel: 'Add Friends',
                        ),
                        Text(
                          'Add Friends',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: baseSize * 0.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Friends exist: stack friends list over faded background
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Background: faded image and text
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.08),
                  Center(
                    child: Opacity(
                      opacity: 0.25,
                      child: Image.asset(
                        'assets/images/freinds.png',
                        width: width * 0.9,
                        height: height * 0.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Kharcha share karo, dosti save karo!',
                      style: GoogleFonts.cabin(fontSize: baseSize * 0.035),
                    ),
                  ),
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
                              fontSize: baseSize * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Material(
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
                              splashColor: Colors.deepPurple.withOpacity(0.3),
                              highlightColor: Colors.deepPurple.withOpacity(0.1),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: baseSize * 0.045,
                                      color: Theme.of(context).colorScheme.inversePrimary,
                                      semanticLabel: 'Add Friends',
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Add Friends',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.inversePrimary,
                                        fontSize: baseSize * 0.04,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                                style: GoogleFonts.cabin(fontSize: baseSize * 0.045),
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
          ),
        ),
      );
    }
  }
}
