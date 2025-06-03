import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double itemWidth = (MediaQuery.of(context).size.width - 40) / 3;
    return Padding(
      padding: EdgeInsets.only(bottom: 10 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Stack(
            children: [
              // Curved Bar Background
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.9),
                  // color: Colors.deepPurple[200],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
              // Animated Bubble
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutQuad,
                left: selectedIndex * itemWidth,
                top: 0,
                child: Container(
                  width: itemWidth,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.15),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Navigation Items
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    // Groups
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/groups');
                          onItemSelected(0);
                        },
                        child: Container(
                          color: Colors.transparent,
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group, color: selectedIndex == 0 ? Colors.deepPurple : Colors.grey[700], size: 28),
                              if (selectedIndex == 0) ...[
                                SizedBox(width: 8),
                                Text(
                                  'Groups',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Friends (center)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/freinds');
                          onItemSelected(1);
                        },
                        child: Container(
                          color: Colors.transparent,
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: selectedIndex == 1 ? Colors.deepPurple : Colors.grey[700], size: 28),
                              if (selectedIndex == 1) ...[
                                SizedBox(width: 8),
                                Text(
                                  'Friends',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Activity
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/activity');
                          onItemSelected(2);
                        },
                        child: Container(
                          color: Colors.transparent,
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_activity, color: selectedIndex == 2 ? Colors.deepPurple : Colors.grey[700], size: 28),
                              if (selectedIndex == 2) ...[
                                SizedBox(width: 8),
                                Text(
                                  'Activity',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}