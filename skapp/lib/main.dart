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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/settings': (context) => SettingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          try {
            final args = settings.arguments as Map<String, dynamic>?;
            final index = args?['index'] as int?;
            // Validate index is within bounds
            if (index != null && (index < 0 || index > 2)) {
              return MaterialPageRoute(
                builder: (context) => const MainPage(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => MainPage(initialIndex: index),
            );
          } catch (e) {
            // If any error occurs during navigation, return to main page
            return MaterialPageRoute(
              builder: (context) => const MainPage(),
            );
          }
        }
        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Page not found'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


