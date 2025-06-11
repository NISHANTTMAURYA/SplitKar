import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:skapp/components/auth_wrapper.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/settings_profile/settings_page.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/offline_banner.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:skapp/services/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';

class ProfileNotifier extends ChangeNotifier {
  final _logger = Logger('ProfileNotifier');
  String? _name;
  String? _email;
  String? _photoUrl;
  String? _username;
  String? _firstName;
  String? _lastName;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get name => _name;
  String? get email => _email;
  String? get photoUrl => _photoUrl;
  String? get username => _username;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _logger.warning('Setting profile error: $error');
    _error = error;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? photoUrl,
    String? username,
    String? firstName,
    String? lastName,
  }) {
    _logger.info('Updating profile state:');
    _logger.info('- Current name: $_name');
    _logger.info('- New name: $name');
    _logger.info('- Current email: $_email');
    _logger.info('- New email: $email');
    _logger.info('- Current photoUrl: $_photoUrl');
    _logger.info('- New photoUrl: $photoUrl');
    _logger.info('- Current username: $_username');
    _logger.info('- New username: $username');
    _logger.info('- Current firstName: $_firstName');
    _logger.info('- New firstName: $firstName');
    _logger.info('- Current lastName: $_lastName');
    _logger.info('- New lastName: $lastName');

    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _username = username;
    _firstName = firstName;
    _lastName = lastName;
    _error = null;

    _logger.info('Profile state updated successfully');
    notifyListeners();
  }

  void clearProfile() {
    _logger.info('Clearing profile state');
    _name = null;
    _email = null;
    _photoUrl = null;
    _username = null;
    _firstName = null;
    _lastName = null;
    _error = null;
    notifyListeners();
  }
}

void main() {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();

  // Now we can safely set system UI mode
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

  // Create singleton instances
  final notificationService = NotificationService();
  final navigationService = NavigationService();
  final alertService = AlertService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileNotifier>(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider<NotificationService>.value(value: notificationService),
        Provider<NavigationService>.value(value: navigationService),
        ChangeNotifierProvider<AlertService>.value(value: alertService),
        ChangeNotifierProvider<FriendsProvider>(create: (_) => FriendsProvider()),
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
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    
    return MaterialApp(
      navigatorKey: navigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SplitKar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => Scaffold(
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
            );
          case '/main':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => MainPage(
                initialIndex: 0,
              ),
            );
          case '/settings':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const SettingsPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Route ${settings.name} not found'),
                ),
              ),
            );
        }
      },
    );
  }
}


