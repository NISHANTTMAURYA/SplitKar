import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:skapp/components/auth_wrapper.dart';
import 'package:skapp/pages/settings_profile/settings_page.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/offline_banner.dart';

class ProfileNotifier extends ChangeNotifier {
  String? name;
  String? email;
  String? photoUrl;
  String? username;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void updateProfile({String? name, String? email, String? photoUrl, String? username}) {
    this.name = name;
    this.email = email;
    this.photoUrl = photoUrl;
    this.username = username;
    _error = null; // Clear any previous errors
    notifyListeners();
  }

  void clearProfile() {
    name = null;
    email = null;
    photoUrl = null;
    username = null;
    _error = null;
    notifyListeners();
  }
}

void main() {
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    final display = ui.PlatformDispatcher.instance.displays.first;
        print('Display refresh rate: ${display.refreshRate}');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SplitKar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            AuthWrapper(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(),
            ),
          ],
        ),
      ),
      routes: {
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}


