import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/login_page.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:provider/provider.dart';
import 'package:skapp/services/navigation_service.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    
    return FutureBuilder<bool>(
      future: _authService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: CustomLoader(size: 40));
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Use navigation service to go to main page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigationService.navigateToMain();
          });
          return Scaffold(body: CustomLoader(size: 40));
        }

        return LoginPage();
      },
    );
  }
}
