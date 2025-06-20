import 'package:flutter/material.dart';

// Just copy this widget to your project
class ThemeToggleSwitch extends StatefulWidget {
  final Function(bool) onChanged; // This function will be called when toggled
  final bool initialValue; // Add initial value parameter

  const ThemeToggleSwitch({
    Key? key,
    required this.onChanged,
    this.initialValue = false, // Default to false (light theme)
  }) : super(key: key);

  @override
  State<ThemeToggleSwitch> createState() => _ThemeToggleSwitchState();
}

class _ThemeToggleSwitchState extends State<ThemeToggleSwitch>
    with SingleTickerProviderStateMixin {
  bool _isDark = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialValue; // Initialize with the provided value
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    // Set initial animation state
    if (_isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isDark = !_isDark;
      if (_isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onChanged(_isDark); // This calls your function
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 70,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _isDark
                ? [Colors.indigo.shade800, Colors.indigo.shade600]
                : [Colors.orange.shade300, Colors.yellow.shade400],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isDark ? Colors.indigo : Colors.orange).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icons
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.wb_sunny,
                color: Colors.white.withOpacity(_isDark ? 0.3 : 1.0),
                size: 16,
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.nightlight_round,
                color: Colors.white.withOpacity(_isDark ? 1.0 : 0.3),
                size: 16,
              ),
            ),
            // Moving circle
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: 3 + (_animation.value * 32),
                  top: 3,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isDark ? Icons.nightlight_round : Icons.wb_sunny,
                      color: _isDark ? Colors.indigo.shade700 : Colors.orange.shade600,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// HOW TO USE IT - Copy this example to your page
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isDarkTheme = false;

  // This function will be called when toggle is switched
  void handleThemeChange(bool isDark) {
    setState(() {
      isDarkTheme = isDark;
    });

    // Here you can add your theme switching logic
    print(isDark ? "Switched to Dark Theme" : "Switched to Light Theme");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('My App'),
        backgroundColor: isDarkTheme ? Colors.grey[800] : Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ThemeToggleSwitch(
              onChanged: handleThemeChange, // Pass your function here
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isDarkTheme ? '🌙 Dark Mode Active' : '☀️ Light Mode Active',
              style: TextStyle(
                fontSize: 20,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ThemeToggleSwitch(
              onChanged: handleThemeChange,
            ),
          ],
        ),
      ),
    );
  }
}
