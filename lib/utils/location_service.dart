import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:FitStart/core/cache/cache_manager.dart';

class LocationService {
  LocationService._();

  // Cache keys
  static const String _cacheKeyPosition = 'last_known_position';
  static const String _cacheKeyAddress = 'last_known_address';
  static const String _cacheKeyPermissionStatus = 'location_permission_status';
  
  // Cache last position in memory for quick access
  static Position? _lastKnownPosition;
  static String? _lastKnownAddress;

  /// Initialize location service - load cached data
  static Future<void> init() async {
    await _loadCachedPosition();
  }

  /// Load cached position from storage
  static Future<void> _loadCachedPosition() async {
    try {
      final positionData = await CacheManager.get(
        _cacheKeyPosition,
        maxAge: const Duration(hours: 24), // Cache for 24 hours
      );
      
      if (positionData != null && positionData is Map) {
        // Convert dynamic Map to Map<String, dynamic>
        final Map<String, dynamic> data = Map<String, dynamic>.from(positionData);
        
        _lastKnownPosition = Position(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
          accuracy: (data['accuracy'] as num).toDouble(),
          altitude: (data['altitude'] as num).toDouble(),
          heading: (data['heading'] as num).toDouble(),
          speed: (data['speed'] as num).toDouble(),
          speedAccuracy: (data['speedAccuracy'] as num).toDouble(),
          altitudeAccuracy: (data['altitudeAccuracy'] as num).toDouble(),
          headingAccuracy: (data['headingAccuracy'] as num).toDouble(),
        );
        print('✅ Loaded cached position from storage');
      }
      
      final address = await CacheManager.get(
        _cacheKeyAddress,
        maxAge: const Duration(hours: 24),
      );
      if (address != null && address is String) {
        _lastKnownAddress = address;
      }
    } catch (e) {
      print('⚠️  Error loading cached position: $e');
      // Clear corrupted cache
      await CacheManager.delete(_cacheKeyPosition);
      await CacheManager.delete(_cacheKeyAddress);
    }
  }

  /// Cache current position for later use
  static Future<void> _cachePosition(Position position, String? address) async {
    try {
      final positionData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'altitudeAccuracy': position.altitudeAccuracy,
        'headingAccuracy': position.headingAccuracy,
      };
      
      await CacheManager.set(_cacheKeyPosition, positionData);
      
      if (address != null) {
        await CacheManager.set(_cacheKeyAddress, address);
        _lastKnownAddress = address;
      }
      
      _lastKnownPosition = position;
    } catch (e) {
      print('⚠️  Error caching position: $e');
    }
  }

  /// Get last known position from cache (fast, no GPS required)
  static Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }

  /// Get last known address from cache
  static String? getLastKnownAddress() {
    return _lastKnownAddress;
  }

  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location services are disabled');
      return false; // User must enable in settings
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permission denied forever');
      return false;
    }

    // Cache permission status
    await CacheManager.set(_cacheKeyPermissionStatus, true);
    return true;
  }

  /// Check if we have cached permission
  static Future<bool> hasCachedPermission() async {
    final cached = await CacheManager.get<bool>(
      _cacheKeyPermissionStatus,
      maxAge: const Duration(hours: 12),
    );
    return cached ?? false;
  }

  /// Get current position with smart caching
  /// If forceRefresh is false, returns cached position if available and recent
  static Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    // Return cached position if available and not forcing refresh
    if (!forceRefresh && _lastKnownPosition != null) {
      final age = DateTime.now().difference(_lastKnownPosition!.timestamp);
      if (age.inMinutes < 30) { // Cache valid for 30 minutes
        print('✅ Using cached position (${age.inMinutes}m old)');
        return _lastKnownPosition;
      }
    }
    
    final ok = await ensurePermission();
    if (!ok) {
      // If permission denied, return last known position if available
      if (_lastKnownPosition != null) {
        print('⚠️  Permission denied, using cached position');
        return _lastKnownPosition;
      }
      return null;
    }
    
    try {
      print('🌍 Fetching fresh GPS position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout after 10 seconds
      );
      
      // Try to get address
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          address = '${pm.street ?? ''}, ${pm.locality ?? ''}, ${pm.postalCode ?? ''}'.trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
        }
      } catch (e) {
        print('⚠️  Could not get address: $e');
      }
      
      // Cache the position
      await _cachePosition(position, address);
      
      print('✅ Fresh position acquired and cached');
      return position;
    } catch (e) {
      print('❌ Error getting current position: $e');
      // Return last known position as fallback
      if (_lastKnownPosition != null) {
        print('⚠️  Using fallback cached position');
        return _lastKnownPosition;
      }
      return null;
    }
  }

  static Future<Placemark?> getCurrentPlacemark({bool forceRefresh = false}) async {
    final position = await getCurrentPosition(forceRefresh: forceRefresh);
    if (position == null) return null;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      return placemarks.first;
    } catch (e) {
      print('❌ Error getting placemark: $e');
      return null;
    }
  }

  /// Manually set location (for user-entered addresses)
  static Future<void> setLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        
        await _cachePosition(position, address);
        print('✅ Location set from address: $address');
      }
    } catch (e) {
      print('❌ Error setting location from address: $e');
    }
  }

  /// Clear cached location data
  static Future<void> clearCache() async {
    _lastKnownPosition = null;
    _lastKnownAddress = null;
    await CacheManager.delete(_cacheKeyPosition);
    await CacheManager.delete(_cacheKeyAddress);
    await CacheManager.delete(_cacheKeyPermissionStatus);
    print('✅ Location cache cleared');
  }

  static double distanceInKm(
      double startLat, double startLng, double endLat, double endLng) {
    final meters =
        Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return meters / 1000.0;
  }
}
