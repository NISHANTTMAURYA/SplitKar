import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class FreindsPage extends StatelessWidget {
  const FreindsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    
    final appBarWidth = MediaQuery.of(context).size.width;
    final double baseSize = width < height ? width : height;
    


    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            
            Center(
              child: Image.asset(
                'assets/images/freinds.png',
                width: width * 0.9,
                height: height * 0.4,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Kharcha share karo, dosti save karo!',
                    style: GoogleFonts.cabin(fontSize: baseSize * 0.035),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              semanticLabel: 'Add Friends',
                            ),
                            Text(
                              'Add Friends',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary,
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
          ],
        ),
      )
    );
      
  }
}
