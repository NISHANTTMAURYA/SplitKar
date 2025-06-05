import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/login_page.dart';
import 'package:skapp/pages/main_page.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return MainPage();
        }

        return LoginPage();
      },
    );
  }
} 