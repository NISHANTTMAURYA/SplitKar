import 'package:flutter/material.dart';

class AnimatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final FocusNode focusNode;
  final bool isPassword;
  final bool isEmail;
  final String? Function(String?)? validator;
  final VoidCallback? onTogglePassword;
  final bool obscureText;

  const AnimatedTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    required this.focusNode,
    this.isPassword = false,
    this.isEmail = false,
    this.validator,
    this.onTogglePassword,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..scale(isFocused ? 1.02 : 1.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          prefixIcon: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Icon(
              prefixIcon,
              key: ValueKey<bool>(isFocused),
              color: isFocused ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
          suffixIcon: isPassword
              ? AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: IconButton(
                    key: ValueKey<bool>(isFocused),
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: isFocused ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    onPressed: onTogglePassword,
                  ),
                )
              : null,
          labelStyle: TextStyle(
            color: isFocused ? Theme.of(context).primaryColor : Colors.grey,
          ),
          floatingLabelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
} 