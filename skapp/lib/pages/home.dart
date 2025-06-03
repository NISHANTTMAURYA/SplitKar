// import 'package:flutter/material.dart';
// import 'package:skapp/main.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
// import 'package:skapp/components/bottomNavbar.dart';
// import 'package:skapp/components/drawer.dart';
// import 'package:skapp/components/appbar.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;

  
//   @override
//   Widget build(BuildContext context) {
//     final double height = MediaQuery.of(context).size.height;
//     final double width = MediaQuery.of(context).size.width;
    
//     final appBarWidth = MediaQuery.of(context).size.width;
//     final double baseSize = width < height ? width : height;
//     final Color barColor = Theme.of(
//       context,
//     ).colorScheme.surface.withOpacity(0.95);
//     final Color accentColor = Theme.of(context).colorScheme.inversePrimary;
//     final Color iconColor = Colors.grey[600]!;
//     final Color selectedColor = Colors.blueAccent;

//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: CustomAppBar(scaffoldKey: _scaffoldKey),

//       drawer: AppDrawer(
//         selectedIndex: _selectedIndex,
//         onItemSelected: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: <Widget>[
            
//             Center(
//               child: Image.asset(
//                 'assets/images/freinds.png',
//                 width: width * 0.9,
//                 height: height * 0.4,
//               ),
//             ),
//             SizedBox(height: 20),
//             Center(
//               child: Column(
//                 children: [
//                   Text(
//                     'Kharcha share karo, dosti save karo!',
//                     style: GoogleFonts.cabin(fontSize: baseSize * 0.035),
//                   ),
//                   SizedBox(height: 15),
//                   Material(
//                     color: Colors.transparent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: BorderSide(
//                         color: Theme.of(context).colorScheme.inversePrimary,
//                         width: 2,
//                       ),
//                     ),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(12),
//                       splashColor: Colors.deepPurple.withOpacity(0.3),
//                       highlightColor: Colors.deepPurple.withOpacity(0.1),
//                       onTap: () {},
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.add,
//                               size: baseSize * 0.07,
//                               color: Theme.of(
//                                 context,
//                               ).colorScheme.inversePrimary,
//                               semanticLabel: 'Add Friends',
//                             ),
//                             Text(
//                               'Add Friends',
//                               style: TextStyle(
//                                 color: Theme.of(
//                                   context,
//                                 ).colorScheme.inversePrimary,
//                                 fontSize: baseSize * 0.05,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavbar(
//         selectedIndex: _selectedIndex,
//         onItemSelected: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }
