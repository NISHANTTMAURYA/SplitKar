import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skapp/components/alerts/alert_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PageController? pageController;
  final bool is_bottom_needed;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    this.pageController,
    this.is_bottom_needed=true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final alertCount = context.watch<AlertService>().totalCount;
    
    // Calculate responsive sizes
    final titleFontSize = width * 0.09; // Increased from 0.07 to 0.09
    final logoWidth = width * 0.19; // Increased from 0.08 to 0.1
    final logoHeight = height * 0.1; // Increased from 0.04 to 0.05

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: is_bottom_needed ? Colors.white : Colors.deepPurple,
        statusBarIconBrightness: is_bottom_needed ? Brightness.dark : Brightness.light,
        statusBarBrightness: is_bottom_needed ? Brightness.light : Brightness.dark,
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      centerTitle: true,

      bottom: is_bottom_needed ? PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          color: Colors.deepPurple[400],
          height: 0.8,
        ),
      ) : null,

      leadingWidth: 80,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 5, 6),
        child: SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[400],
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
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

      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 6, 20, 6),
          child: SafeArea(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[400],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    splashColor: Colors.deepPurple.withOpacity(0.3),
                    highlightColor: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.read<AlertService>().showAlertSheet(context);
                    },
                    child: Stack(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.notifications_active_outlined, color: Colors.black, size: 26),
                        ),
                        if (alertCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                alertCount > 99 ? '99+' : alertCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],

      title: Center(
        child: GestureDetector(
          onTap: () {
            if (pageController != null && pageController!.page! > 0) {
              pageController!.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else if (onBackPressed != null) {
              onBackPressed!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    "SplitKar",
                    style: GoogleFonts.cabin(
                      fontSize: titleFontSize.clamp(28.0, 36.0), // slightly reduced for safety
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                SizedBox(width: width * 0.01), // slightly reduced spacing
                SizedBox(
                  width: logoWidth.clamp(28.0, 36.0),
                  height: logoHeight.clamp(28.0, 36.0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      'assets/images/wallet.png',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}