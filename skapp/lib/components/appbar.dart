import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CustomAppBar({super.key, required this.scaffoldKey});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AppBar(
      leadingWidth: 80,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
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
                  child: const Icon(Icons.menu, color: Colors.black, size: 25),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.only(left: 10),
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
    );
  }
}