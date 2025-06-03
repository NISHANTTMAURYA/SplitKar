import 'package:flutter/material.dart';
import 'package:skapp/pages/home.dart';
import 'package:skapp/pages/activity.dart';
import 'package:skapp/pages/freinds.dart';
import 'package:skapp/pages/groups.dart';
import 'package:skapp/pages/settings_page.dart';

void main() {
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
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/activity': (context) => ActivityPage(),
        '/freinds': (context) => FreindsPage(),
        '/groups': (context) => GroupsPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}


