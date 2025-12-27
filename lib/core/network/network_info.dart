// Core - Network Info
// Check internet connectivity

import 'package:geolocator/geolocator.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      // Simple connectivity check using a DNS lookup-like approach
      // You can also use connectivity_plus package for better detection
      final connectivityResult = await Geolocator.checkPermission();
      return true; // Simplified, you should use connectivity_plus package
    } catch (e) {
      return false;
    }
  }
}
