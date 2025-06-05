import 'package:flutter/material.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/login_page.dart';
import 'package:skapp/pages/settings_page.dart';
import 'package:skapp/services/auth_service.dart';

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
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return MainPage();
          }
          return LoginPage();
        },
      ),
      routes: {
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}


