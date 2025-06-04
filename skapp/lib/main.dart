import 'package:flutter/material.dart';
import 'package:skapp/pages/main_page.dart';
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
      home: const MainPage(),
      routes: {
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}


