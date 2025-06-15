class AppConfig {
  // ===============================
  // How to run Django for WiFi debug
  // ===============================
  // 1. Make sure your phone and computer are on the same WiFi network.
  // 2. Find your computer's local IP address (e.g., 192.168.29.203).
  // 3. Start Django with:
  //      python manage.py runserver 0.0.0.0:8000
  // 4. Set the correct flags below.
  // 5. Make sure CORS is enabled for your device and ngrok.
  // ===============================

  // URLs for different environments
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String deviceBaseUrl =
      'http://192.168.29.203:8000/api'; // Replace with your IP
  static const String ngrokBaseUrl =
      'https://a579-2405-201-27-518b-8888-41b-9575-72af.ngrok-free.app/api';

  // Environment flags
  static const bool useEmulator = false; // Android Emulator
  static const bool useNgrok = false; // Ngrok Tunnel

  // Select the correct base URL based on flags
  static String get baseUrl {
    if (useNgrok) {
      return ngrokBaseUrl;
    } else if (useEmulator) {
      return emulatorBaseUrl;
    } else {
      return deviceBaseUrl;
    }
  }
}
