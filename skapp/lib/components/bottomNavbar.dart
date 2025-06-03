import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class BottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<String> labels;
  final List<IconData> icons;

  const BottomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.labels,
    required this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double itemWidth = (MediaQuery.of(context).size.width - 40) / labels.length;
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
                    color: Colors.deepPurple.withOpacity(0.3),
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
                  children: List.generate(labels.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onItemSelected(index),
                        child: Container(
                          color: Colors.transparent,
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icons[index], color: selectedIndex == index ? Colors.deepPurple : Colors.grey[700], size: 28),
                              if (selectedIndex == index) ...[
                                SizedBox(width: 8),
                                Text(
                                  labels[index],
                                  style: GoogleFonts.cabin(
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
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}