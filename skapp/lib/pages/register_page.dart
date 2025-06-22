import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/utils/async_action_mixin.dart';
import 'package:skapp/widgets/animated_text_field.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/services/navigation_service.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with AsyncActionMixin<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Focus nodes for animation
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
    _firstNameFocus.addListener(() => setState(() {}));
    _lastNameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final navigationService = Provider.of<NavigationService>(context, listen: false);
    await handleAsyncAction(
      () => _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        password2: _confirmPasswordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      ),
      context,
      navigateOnSuccess: true,
      onSuccess: () => navigationService.navigateToMain(),
    );
  }

  void _navigateBack() {
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    navigationService.goBack();
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
                    flex: 1, // Top section height
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  // Purple container - adjust flex to change height
                  Expanded(
                    flex: 6, // Increase this number to make purple container taller
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[400],
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(150)
                        ),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0,
                              vertical: 16.0
                          ),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(6,0,6,0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 10), // Reduced from 60 to save space
                                    Text(
                                      'Create Account',
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
                                      label: 'Username',
                                      prefixIcon: Icons.person,
                                      focusNode: _usernameFocus,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a username';
                                        }
                                        if (value.length < 3) {
                                          return 'Username must be at least 3 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 8), // Reduced spacing between fields
                                    AnimatedTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      prefixIcon: Icons.email,
                                      focusNode: _emailFocus,
                                      isEmail: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter an email';
                                        }
                                        if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 8),
                                    AnimatedTextField(
                                      controller: _firstNameController,
                                      label: 'First Name (Optional)',
                                      prefixIcon: Icons.person_outline,
                                      focusNode: _firstNameFocus,
                                    ),
                                    SizedBox(height: 8),
                                    AnimatedTextField(
                                      controller: _lastNameController,
                                      label: 'Last Name (Optional)',
                                      prefixIcon: Icons.person_outline,
                                      focusNode: _lastNameFocus,
                                    ),
                                    SizedBox(height: 8),
                                    AnimatedTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      prefixIcon: Icons.lock,
                                      focusNode: _passwordFocus,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onTogglePassword: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 8),
                                    AnimatedTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      prefixIcon: Icons.lock_outline,
                                      focusNode: _confirmPasswordFocus,
                                      isPassword: true,
                                      obscureText: _obscureConfirmPassword,
                                      onTogglePassword: () => setState(
                                            () =>
                                        _obscureConfirmPassword = !_obscureConfirmPassword,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16), // Reduced from 20
                                    ElevatedButton(

                                      onPressed: isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: isLoading
                                          ? CustomLoader(isButtonLoader: true)
                                          : Text(
                                        'Register',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: textScaler.scale(16.0),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8), // Reduced from 12
                                    TextButton(
                                      onPressed: _navigateBack,
                                      child: Text(
                                        'Already have an account? Login',
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
                    ),
                  ),
                ],
              ),
              // Image positioned to overlap the purple container
              Positioned(
                top: height * 0.026, // Adjusted to bring hands above container
                left: 140, // Adjust horizontal position
                child: Image.asset(
                  'assets/images/peeking_crop.png',
                  height: height * 0.16, // Fixed height
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