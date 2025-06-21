import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/utils/app_colors.dart';
class BottomNavbar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<String> labels;
  final List<IconData> icons;

  const BottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.labels,
    required this.icons,
  });

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar>
    with SingleTickerProviderStateMixin {
  late double itemWidth;
  late AnimationController _controller;
  late Animation<double> _leftAnim;
  late Animation<double> _rightAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // To get correct itemWidth after first build
    });
  }

  @override
  void didUpdateWidget(covariant BottomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _prevIndex) {
      _startBubbleAnimation(_prevIndex, widget.selectedIndex);
      _prevIndex = widget.selectedIndex;
    }
  }

  void _startBubbleAnimation(int from, int to) {
    final direction = to > from ? 1 : -1;
    final double startLeft = from * itemWidth;
    final double startRight = (widget.labels.length - from - 1) * itemWidth;
    final double endLeft = to * itemWidth;
    final double endRight = (widget.labels.length - to - 1) * itemWidth;
    final double stretch = ((to - from).abs()) * itemWidth * 0.7;
    if (direction > 0) {
      // Moving right: right side moves first
      _leftAnim = TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: startLeft, end: startLeft),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: startLeft, end: endLeft),
          weight: 50,
        ),
      ]).animate(_controller);
      _rightAnim = TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: startRight, end: startRight - stretch),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: startRight - stretch, end: endRight),
          weight: 50,
        ),
      ]).animate(_controller);
    } else {
      // Moving left: left side moves first (no rightward movement)
      _leftAnim = TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: startLeft, end: endLeft),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: endLeft, end: endLeft),
          weight: 50,
        ),
      ]).animate(_controller);
      _rightAnim = TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: startRight, end: startRight + stretch),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: startRight + stretch, end: endRight),
          weight: 50,
        ),
      ]).animate(_controller);
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    itemWidth = (MediaQuery.of(context).size.width - 40) / widget.labels.length;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 3+ MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        color: Colors.transparent,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Stack(
            children: [
              // Curved Bar Background
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.9),
                  // color: Colors.deepPurple[200],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent,
                      blurRadius: 20,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
              ),
              // True Side-First Stretchy Animated Bubble
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final left = _controller.isAnimating
                      ? _leftAnim.value
                      : widget.selectedIndex * itemWidth;
                  final right = _controller.isAnimating
                      ? _rightAnim.value
                      : (widget.labels.length - widget.selectedIndex - 1) *
                            itemWidth;
                  return Positioned(
                    left: left,
                    right: right,
                    top: 0,
                    child: Container(
                      height: 52,
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
                  );
                },
              ),
              // Navigation Items
              SizedBox(
                height: 52,
                child: Row(
                  children: List.generate(widget.labels.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onItemSelected(index),
                        child: Container(
                          color: Colors.transparent,
                          height: 52,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.icons[index],
                                color: widget.selectedIndex == index
                                    ? Colors.deepPurple
                                    : Colors.grey[700],
                                size: 26,
                              ),
                              if (widget.selectedIndex == index) ...[
                                SizedBox(width: 8),
                                Text(
                                  widget.labels[index],
                                  style: GoogleFonts.cabin(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
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

/*
// ORIGINAL BottomNavbar CODE (StatelessWidget version)
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
                duration: Duration(milliseconds: 500),
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
}*/
