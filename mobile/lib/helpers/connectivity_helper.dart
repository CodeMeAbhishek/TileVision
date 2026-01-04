import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  /// Check if device has internet connection
  static Future<bool> isConnected() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      // If check fails, assume connected (let API call handle it)
      return true;
    }
  }
  
  /// Get connectivity stream for listening to changes
  static Stream<ConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }
  
  /// Check if connection is WiFi (faster)
  static Future<bool> isWifi() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }
}

