import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final bool page_color_white;

  const CustomAppBar({
    super.key, 
    required this.scaffoldKey,
    this.pageController,
    this.page_color_white=false
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AppBar(

      leadingWidth: 80,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 5, 6),
        child: SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              child: Ink(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  splashColor: Colors.deepPurple.withOpacity(0.3),
                  highlightColor: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                  child: const Icon(Icons.menu_rounded, color: Colors.black, size: 26),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: page_color_white?Colors.white:Colors.transparent,
      centerTitle: true,
      title: Center(
        child: GestureDetector(
          onTap: () {
            if (pageController != null && pageController!.page! > 0) {
              pageController!.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Container(
              // color: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "SplitKar",
                    style: GoogleFonts.cabin(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.only(bottom: 5),
                    width: width * 0.13,
                    height: height * 0.9,
                    child: Image.asset('assets/images/wallet.png'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}