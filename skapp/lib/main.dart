import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skapp/components/auth_wrapper.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/screens/group_chat_screen.dart';
import 'package:skapp/pages/screens/friend_chat_screen.dart';
import 'package:skapp/pages/screens/group_chat_screen.dart';
import 'package:skapp/pages/settings_profile/settings_page.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/widgets/offline_banner.dart';
import 'package:skapp/services/notification_service.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:skapp/components/alerts/alert_service.dart';
import 'package:skapp/pages/friends/friends_provider.dart';
import 'package:skapp/pages/groups/group_provider.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/utils/app_colors.dart';
import 'package:skapp/pages/notification_playground.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class ProfileNotifier extends ChangeNotifier {
  final _logger = Logger('ProfileNotifier');
  String? _name;
  String? _email;
  String? _photoUrl;
  String? _username;
  String? _profileCode;
  bool _isLoading = false;
  String? _error;
  String? _firstName;
  String? _lastName;

  bool get isLoading => _isLoading;
  String? get name => _name;
  String? get email => _email;
  String? get photoUrl => _photoUrl;
  String? get username => _username;
  String? get profileCode => _profileCode;
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
    String? profileCode,
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
    _logger.info('- Current profileCode: $_profileCode');
    _logger.info('- New profileCode: $profileCode');

    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _username = username;
    _firstName = firstName;
    _lastName = lastName;
    _profileCode = profileCode;
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
    _profileCode = null;
    _error = null;
    notifyListeners();
  }
}

void main() async {
  // Initialize Flutter bindings first
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final AuthService auth = AuthService();
  dynamic userId = await auth.getUserId();
  await loadThemePref(userId);

  // Now we can safely set system UI mode
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.deepPurple, // Status bar background color
      statusBarIconBrightness:
          Brightness.dark, // Status bar icons (light for dark background)
      statusBarBrightness: Brightness.dark, // For iOS
    ),
  );

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
        ChangeNotifierProvider<ProfileNotifier>(
          create: (_) => ProfileNotifier(),
        ),
        ChangeNotifierProvider<NotificationService>.value(
          value: notificationService,
        ),
        Provider<NavigationService>.value(value: navigationService),
        ChangeNotifierProvider<AlertService>.value(value: alertService),
        ChangeNotifierProvider<FriendsProvider>(
          create: (_) => FriendsProvider(),
        ),
        ChangeNotifierProvider<GroupProvider>(create: (_) => GroupProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);
ValueNotifier<bool> get isDarkMode => _isDarkMode;

// Add loading state for theme change
final ValueNotifier<bool> _isThemeChanging = ValueNotifier(false);
ValueNotifier<bool> get isThemeChanging => _isThemeChanging;

// Function to get system theme
bool getSystemTheme() {
  final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  return brightness == Brightness.dark;
}

// ParallelLoading function
Future<void> parallelLoading(
    Future<void> Function() operation,
    Duration duration,
    ) async {
  // Start the operation
  final operationFuture = operation();

  // Wait for the specified duration
  final timerFuture = Future.delayed(duration);

  // Race between operation completion and timer
  await Future.any([operationFuture, timerFuture]);
}

// FutureRacing function
Future<T> futureRacing<T>(List<Future<T>> futures) async {
  return await Future.any(futures);
}

// Add this function:
void toggleAppTheme() {
  _isDarkMode.value = !_isDarkMode.value;
}

// Modified loadThemePref function with system theme detection
Future<void> loadThemePref(dynamic userID) async {
  final prefs = await SharedPreferences.getInstance();
  final String prefKey = 'themepref_$userID';

  // Try to use backend value if available
  final bool? backendIsDark = ProfileApi().cachedIsDarkMode;
  if (backendIsDark != null) {
    _isDarkMode.value = backendIsDark;
    await prefs.setBool(prefKey, backendIsDark);
    print('Loaded theme from backend for $userID: $backendIsDark');
    return;
  }

  // Check if preference exists
  if (prefs.containsKey(prefKey)) {
    // Load saved preference
    final isDark = prefs.getBool(prefKey) ?? true;
    print('Loaded saved theme preference for $userID: $isDark');
    _isDarkMode.value = isDark;
  } else {
    // First time launch - use system theme
    final systemIsDark = getSystemTheme();
    print('First time launch - using system theme for $userID: $systemIsDark');
    _isDarkMode.value = systemIsDark;

    // Optionally save the system theme as initial preference
    try {
      await prefs.setBool(prefKey, systemIsDark);
      print('Saved initial system theme preference for $userID');
    } catch (e) {
      print('Failed to save initial theme preference: $e');
    }
  }
}

// Alternative version that doesn't save system theme initially
Future<void> loadThemePrefWithoutSaving(dynamic userID) async {
  final prefs = await SharedPreferences.getInstance();
  final String prefKey = 'themepref_$userID';

  if (prefs.containsKey(prefKey)) {
    // Load saved preference
    final isDark = prefs.getBool(prefKey) ?? true;
    print('Loaded saved theme preference for $userID: $isDark');
    _isDarkMode.value = isDark;
  } else {
    // First time launch - use system theme but don't save it
    final systemIsDark = getSystemTheme();
    print('First time launch - using system theme for $userID: $systemIsDark');
    _isDarkMode.value = systemIsDark;
  }
}

// New function for theme change with loading
Future<void> toggleAppThemeWithLoading() async {
  final prefs = await SharedPreferences.getInstance();
  final AuthService auth = AuthService();
  dynamic userId = await auth.getUserId();

  if (_isThemeChanging.value) return; // Prevent multiple simultaneous changes

  // Add delay to allow button animation to be visible
  await Future.delayed(Duration(milliseconds: 300));

  _isThemeChanging.value = true;

  try {
    await parallelLoading(() async {
      // Theme change happens immediately when loading starts
      final newIsDark = !_isDarkMode.value;
      _isDarkMode.value = newIsDark;
      try {
        await prefs.setBool('themepref_$userId', newIsDark);
        print('Saved theme preference to shared preferences for user $userId');
      } catch (e) {
        print('Saving to shared preferences failed: $e');
      }

      // Make API call to update backend
      try {
        await ProfileApi().setDarkMode(isDarkMode: newIsDark);
        print('Updated dark mode in backend for user $userId');
      } catch (e) {
        print('Failed to update dark mode in backend: $e');
        // Optionally: show a snackbar or revert the local change if you want strict sync
      }

      // Then wait for the remaining time
      await Future.delayed(
        Duration(milliseconds: 2700),
      ); // 3 seconds total - 300ms delay
    }, Duration(seconds: 3));
  } finally {
    _isThemeChanging.value = false;
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
    initialization();
  }
  Future<void> initialization() async {
    await Future.delayed(Duration(seconds: 1));
    FlutterNativeSplash.remove();
  }


  @override
  Widget build(BuildContext context) {
    final display = ui.PlatformDispatcher.instance.displays.first;
    print('Display refresh rate: ${display.refreshRate}');
    final navigationService = Provider.of<NavigationService>(
      context,
      listen: false,
    );



    return ValueListenableBuilder(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        return MaterialApp(
          navigatorKey: navigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'SplitKar',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            extensions: const [
              AppColorScheme(

                textColor: KPureBlack,
                iconColor: KDeepPurple400,
                shadowColor: KDeepPurple400,
                cardColor: KPureWhite,
                selectedNavColor: Colors.deepPurple,
                unselectedNavColor: Colors.grey,
                cardColor2: KDeepPurple400,

              ),
            ],
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Color(0xFF2A203D),
            //221B2F little more purple
            //2A203D
            //blue purple 1E1E2E
            colorScheme: ColorScheme.dark().copyWith(
              inversePrimary: KDeepPurple400, // Custom inversePrimary for dark mode
            ),
            extensions: const [
              AppColorScheme(


                textColor: KPureWhite,
                iconColor: KPureWhite,
                shadowColor: KDeepPurpleAccent100,
                cardColor: KDeepPurple400,
                selectedNavColor: KDeepPurpleAccent100,
                unselectedNavColor: Color(0xFF2A203D),
                cardColor2: ColorMoredarkerThanScaffold


              ),

            ],
          ),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                // Global theme changing overlay
                ValueListenableBuilder<bool>(
                  valueListenable: isThemeChanging,
                  builder: (context, isChanging, _) {
                    if (!isChanging) return SizedBox.shrink();
                    return Container(
                      color: isDarkMode.value ? Color(0xFF2A203D) : Colors.white,
                      child: CustomLoader(),
                    );
                  },
                ),
              ],
            );
          },
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
                  builder: (context) => MainPage(initialIndex: 0),
                );
              case '/settings':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => const SettingsPage(),
                );
              case '/friend-chat':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null || !args.containsKey('chatName')) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: Friend chat details not provided.'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => FriendChatScreen(
                    chatName: args['chatName'] as String,
                    chatImageUrl: args['chatImageUrl'] as String?,
                  ),
                );
              case '/group-chat':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null ||
                    !args.containsKey('chatName') ||
                    !args.containsKey('groupId')) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: Group chat details not provided.'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => GroupChatScreen(
                    key: ValueKey('group_chat_${args['groupId']}'),
                    chatName: args['chatName'] as String,
                    chatImageUrl: args['chatImageUrl'] as String?,
                    groupId: args['groupId'] as int,
                  ),
                );
              case '/notification-playground':
                return MaterialPageRoute(
                  builder: (context) => NotificationPlayground(),
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
      },
    );
  }
}
