import 'package:flutter/material.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/pages/main_page.dart';
import 'package:skapp/utils/async_action_mixin.dart';
import 'package:skapp/widgets/animated_text_field.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with AsyncActionMixin<RegisterPage> {
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
      successPage: MainPage(),
    );
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
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
                SizedBox(height: 16),
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                AnimatedTextField(
                  controller: _firstNameController,
                  label: 'First Name (Optional)',
                  prefixIcon: Icons.person_outline,
                  focusNode: _firstNameFocus,
                ),
                SizedBox(height: 16),
                AnimatedTextField(
                  controller: _lastNameController,
                  label: 'Last Name (Optional)',
                  prefixIcon: Icons.person_outline,
                  focusNode: _lastNameFocus,
                ),
                SizedBox(height: 16),
                AnimatedTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock,
                  focusNode: _passwordFocus,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
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
                SizedBox(height: 16),
                AnimatedTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  focusNode: _confirmPasswordFocus,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator()
                      : Text('Register'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateBack,
                  child: Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 