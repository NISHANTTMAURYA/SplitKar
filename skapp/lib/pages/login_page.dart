import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/pages/register_page.dart';
import 'package:skapp/utils/async_action_mixin.dart';
import 'package:skapp/widgets/animated_text_field.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:flutter/services.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with AsyncActionMixin<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Focus nodes for animation
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final navigationService = Provider.of<NavigationService>(context, listen: false);
    await handleAsyncAction(
      () => _authService.loginWithEmailOrUsername(
        _usernameController.text.trim(),
        _passwordController.text,
      ),
      context,
      navigateOnSuccess: true,
      onSuccess: () => navigationService.navigateToMain(),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    await handleAsyncAction(
      () => _authService.signInWithGoogle(),
      context,
      navigateOnSuccess: true,
      onSuccess: () => navigationService.navigateToMain(),
    );
  }

  void _navigateToRegister() {
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // Background sections
              Column(
                children: [
                  // Top section (white/background)
                  Expanded(
                    flex: 1, // Reduced from 2
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  // Purple container - increased height
                  Expanded(
                    flex: 3, // Increased from 4
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[400],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(150),
                        ),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 22.0,
                            vertical: 20.0,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 20,
                                ), // Extra space for overlapping image
                                Text(
                                  'Welcome Back!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.black,
                                        fontSize: textScaler.scale(
                                          Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.fontSize ??
                                              24.0,
                                        ),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                AnimatedTextField(
                                  controller: _usernameController,
                                  label: 'Username or Email',
                                  prefixIcon: Icons.person,
                                  focusNode: _usernameFocus,
                                  isEmail: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username or email';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 12),
                                AnimatedTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  prefixIcon: Icons.lock,
                                  focusNode: _passwordFocus,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? CustomLoader(isButtonLoader: true)
                                      : Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: textScaler.scale(16.0),
                                          ),
                                        ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'OR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: textScaler.scale(14.0),
                                  ),
                                ),
                                SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  icon: Image.asset(
                                    'assets/images/google_logo.png',
                                    height: 20,
                                  ),
                                  label: Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14.0),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.black, width: 1.5),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextButton(
                                  onPressed: _navigateToRegister,
                                  child: Text(
                                    'Don\'t have an account? Register',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Image positioned to overlap the purple container
              Positioned(
                top:
                    height *
                    0.092, // Moved up from 0.12 to bring hands above container
                left: 120, // Adjust horizontal position
                child: Image.asset(
                  'assets/images/peeking_crop.png',
                  height: height * 0.22, // Fixed height
                  // Fixed width to prevent size changes
                  fit: BoxFit.contain, // Maintain aspect ratio
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
