import 'package:flutter/material.dart';
import 'package:skapp/components/auth_wrapper.dart';
import 'package:skapp/pages/settings_profile/settings_page.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';


void main() {

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.deepPurple, // Status bar background color
    statusBarIconBrightness: Brightness.dark, // Status bar icons (light for dark background)
    statusBarBrightness: Brightness.dark, // For iOS
  ));
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      title: 'SplitKar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthWrapper(),
      routes: {
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}


