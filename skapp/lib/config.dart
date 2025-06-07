class AppConfig {
  // ===============================
  // How to run Django for WiFi debug
  // ===============================
  // 1. Make sure your phone and computer are on the same WiFi network.
  // 2. Find your computer's local IP address (e.g., 192.168.29.203).
  // 3. Start Django with:
  //      python manage.py runserver 0.0.0.0:8000
  // 4. Set deviceBaseUrl to 'http://<your-ip>:8000/api'
  // 5. Make sure CORS is enabled for your device.
  // ===============================

  // Use '10.0.2.2' for Android emulator, your local IP for real device
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String deviceBaseUrl =
      'http://192.168.29.203:8000/api'; // <-- replace with your local IP

  // Change this to switch between emulator and device
  static const bool useEmulator =
      false; // Set to true if using emulator, false if using real device

  static String get baseUrl => useEmulator ? emulatorBaseUrl : deviceBaseUrl;
}
