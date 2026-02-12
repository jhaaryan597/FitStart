import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/services/api_service.dart';

/// Service for storing bookings locally
/// This provides offline access and backup for booking data
class LocalBookingService {
  static const String _boxName = 'local_bookings';
  static Box? _box;

  /// Initialize the local booking service
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// Get current user email from cache
  static Future<String?> _getCurrentUserEmail() async {
    try {
      final userBox = await Hive.openBox('user_cache');
      return userBox.get('email') as String?;
    } catch (e) {
      return null;
    }
  }

  /// Generate user-specific key for booking
  static String _getUserBookingKey(String bookingId, String? userEmail) {
    if (userEmail != null && userEmail.isNotEmpty) {
      return '${userEmail}_$bookingId';
    }
    return bookingId;
  }

  /// Save a booking locally
  static Future<void> saveBooking(Map<String, dynamic> booking) async {
    await init();
    print('🔍 LocalBookingService: Getting current user email...');
    final userEmail = await _getCurrentUserEmail();
    print('📧 LocalBookingService: User email = $userEmail');

    final id = booking['_id'] ??
        booking['id'] ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Add user email to booking
    booking['userEmail'] = userEmail;

    final key = _getUserBookingKey(id, userEmail);
    print('🔑 LocalBookingService: Saving with key = $key');
    await _box?.put(key, booking);
    print('✅ LocalBookingService: Booking saved successfully');
  }

  /// Get all local bookings for current user
  static Future<List<Map<String, dynamic>>> getBookings() async {
    await init();
    print('🔍 LocalBookingService.getBookings: Starting...');
    final userEmail = await _getCurrentUserEmail();
    print('📧 LocalBookingService.getBookings: User email = $userEmail');
    final bookings = <Map<String, dynamic>>[];

    // If no user email, return empty list for privacy
    if (userEmail == null || userEmail.isEmpty) {
      print(
          '⚠️ LocalBookingService.getBookings: No user email, returning empty list');
      return bookings;
    }

    print(
        '🔍 LocalBookingService.getBookings: Checking ${_box?.keys.length ?? 0} keys...');
    for (var key in _box?.keys ?? []) {
      final data = _box?.get(key);
      if (data != null) {
        final booking = Map<String, dynamic>.from(data);
        // Only return bookings that match current user's email
        final bookingEmail = booking['userEmail'] as String?;
        if (bookingEmail != null && bookingEmail == userEmail) {
          bookings.add(booking);
          print(
              '✅ LocalBookingService.getBookings: Found matching booking with key $key');
        } else {
          print(
              '⏭️ LocalBookingService.getBookings: Skipping booking with email $bookingEmail');
        }
      }
    }

    print(
        '✅ LocalBookingService.getBookings: Found ${bookings.length} bookings for $userEmail');

    // Sort by created date (newest first)
    bookings.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at'] ?? a['createdAt'] ?? '') ??
              DateTime.now();
      final bDate =
          DateTime.tryParse(b['created_at'] ?? b['createdAt'] ?? '') ??
              DateTime.now();
      return bDate.compareTo(aDate);
    });

    return bookings;
  }

  /// Get bookings with API fallback
  static Future<Map<String, dynamic>> getBookingsWithFallback() async {
    try {
      print('🔍 getBookingsWithFallback: Trying API first...');
      // Try API first
      final apiResult = await ApiService.getBookings();
      print(
          '📡 getBookingsWithFallback: API result = ${apiResult['success']}, data count = ${(apiResult['data'] as List?)?.length ?? 0}');

      if (apiResult['success'] == true && apiResult['data'] != null) {
        final List<dynamic> apiBookings = apiResult['data'];

        // Save to local storage for offline access
        print(
            '💾 getBookingsWithFallback: Saving ${apiBookings.length} API bookings to local...');
        for (var booking in apiBookings) {
          await saveBooking(Map<String, dynamic>.from(booking));
        }

        // ALWAYS merge with local bookings to show Pay at Venue bookings
        print('🔍 getBookingsWithFallback: Fetching local bookings...');
        final localBookings = await getBookings();
        print(
            '📦 getBookingsWithFallback: Found ${localBookings.length} local bookings');

        // Merge API and local bookings (remove duplicates by ID)
        final mergedBookings = [...apiBookings];
        final apiIds = apiBookings.map((b) => b['_id'] ?? b['id']).toSet();

        for (var localBooking in localBookings) {
          final localId = localBooking['_id'] ?? localBooking['id'];
          if (!apiIds.contains(localId)) {
            mergedBookings.add(localBooking);
            print(
                '➕ getBookingsWithFallback: Added local-only booking: $localId');
          }
        }

        print(
            '✅ getBookingsWithFallback: Returning ${mergedBookings.length} total bookings (API + local)');
        return {
          'success': true,
          'data': mergedBookings,
          'source': 'api+local',
        };
      }

      // Fallback to local storage
      print(
          '🔍 getBookingsWithFallback: API failed, using local storage only...');
      final localBookings = await getBookings();
      if (localBookings.isNotEmpty) {
        print(
            '✅ getBookingsWithFallback: Returning ${localBookings.length} local bookings');
        return {
          'success': true,
          'data': localBookings,
          'source': 'local',
        };
      }

      // Return demo bookings if no data exists
      print(
          '⚠️ getBookingsWithFallback: No bookings found, returning demo data');
      final userEmail = await _getCurrentUserEmail();
      return {
        'success': true,
        'data': _generateDemoBookings(userEmail),
        'source': 'demo',
      };
    } catch (e) {
      print('❌ getBookingsWithFallback: Error = $e');
      // Return local data on error
      final localBookings = await getBookings();
      if (localBookings.isNotEmpty) {
        print(
            '✅ getBookingsWithFallback: Returning ${localBookings.length} local bookings after error');
        return {
          'success': true,
          'data': localBookings,
          'source': 'local',
        };
      }

      print(
          '⚠️ getBookingsWithFallback: No local bookings after error, returning demo data');
      final userEmail = await _getCurrentUserEmail();
      return {
        'success': true,
        'data': _generateDemoBookings(userEmail),
        'source': 'demo',
      };
    }
  }

  /// Save a new booking after payment
  static Future<Map<String, dynamic>> recordBooking({
    required String venueId,
    required String venueName,
    required String venueType,
    required String bookingDate,
    required List<String> timeSlots,
    required int totalAmount,
    required String paymentStatus,
    String? paymentMethod,
    String? paymentId,
    String? venueAddress,
    String? venuePhone,
  }) async {
    await init();
    final userEmail = await _getCurrentUserEmail();

    final booking = {
      '_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'userEmail': userEmail,
      'venue': {
        '_id': venueId,
        'name': venueName,
        'type': venueType,
        'address': venueAddress ?? '',
        'phoneNumber': venuePhone ?? '',
      },
      'bookingDate': bookingDate,
      'timeSlots': timeSlots.map((slot) {
        final parts = slot.split(' - ');
        return {
          'startTime': parts.isNotEmpty ? parts[0] : slot,
          'endTime': parts.length > 1 ? parts[1] : slot,
        };
      }).toList(),
      'pricing': {
        'totalAmount': totalAmount,
      },
      'payment': {
        'status': paymentStatus,
        'method': paymentMethod ?? 'razorpay',
        'paymentId': paymentId,
      },
      'bookingStatus': paymentStatus == 'completed' ? 'confirmed' : 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await saveBooking(booking);

    // Also try to sync with backend
    try {
      await ApiService.createBooking(
        venueId: venueId,
        date: DateTime.parse(bookingDate),
        startTime: timeSlots.first.split(' - ').first,
        endTime: timeSlots.last.split(' - ').last,
        totalPrice: totalAmount.toDouble(),
        additionalInfo: {
          'paymentStatus': paymentStatus,
          'paymentMethod': paymentMethod,
          'paymentId': paymentId,
        },
      );
    } catch (e) {
      print('Failed to sync booking with backend: $e');
    }

    return {
      'success': true,
      'data': booking,
    };
  }

  /// Generate demo bookings for display
  static List<Map<String, dynamic>> _generateDemoBookings(String? userEmail) {
    final now = DateTime.now();

    return [
      {
        '_id': 'demo_1',
        'userEmail': userEmail,
        'venue': {
          '_id': 'venue_1',
          'name': 'Elite Basketball Arena',
          'type': 'Basketball',
          'address': 'Sector 15, Gurugram',
        },
        'bookingDate': '${now.day}/${now.month}/${now.year}',
        'timeSlots': [
          {'startTime': '10:00 AM', 'endTime': '11:00 AM'},
          {'startTime': '11:00 AM', 'endTime': '12:00 PM'},
        ],
        'pricing': {'totalAmount': 1200},
        'payment': {'status': 'completed', 'method': 'razorpay'},
        'bookingStatus': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        '_id': 'demo_2',
        'userEmail': userEmail,
        'venue': {
          '_id': 'venue_2',
          'name': 'Green Valley Cricket Ground',
          'type': 'Cricket',
          'address': 'DLF Phase 4, Gurugram',
        },
        'bookingDate':
            '${now.subtract(const Duration(days: 5)).day}/${now.month}/${now.year}',
        'timeSlots': [
          {'startTime': '06:00 AM', 'endTime': '08:00 AM'},
        ],
        'pricing': {'totalAmount': 2500},
        'payment': {'status': 'completed', 'method': 'razorpay'},
        'bookingStatus': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        '_id': 'demo_3',
        'userEmail': userEmail,
        'venue': {
          '_id': 'venue_3',
          'name': 'FitLife Premium Gym',
          'type': 'Gym',
          'address': 'MG Road, Delhi',
        },
        'bookingDate':
            '${now.add(const Duration(days: 1)).day}/${now.month}/${now.year}',
        'timeSlots': [
          {'startTime': '07:00 PM', 'endTime': '08:00 PM'},
        ],
        'pricing': {'totalAmount': 500},
        'payment': {'status': 'pending', 'method': 'pay_at_venue'},
        'bookingStatus': 'pending',
        'createdAt': now.toIso8601String(),
      },
    ];
  }

  /// Update booking status
  static Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await init();
    final booking = _box?.get(bookingId);
    if (booking != null) {
      final updated = Map<String, dynamic>.from(booking);
      updated['bookingStatus'] = status;
      updated['payment'] = {
        ...Map<String, dynamic>.from(updated['payment'] ?? {}),
        'status': status == 'confirmed' ? 'completed' : status,
      };
      await _box?.put(bookingId, updated);
    }
  }

  /// Delete a booking locally
  static Future<void> deleteBooking(String bookingId) async {
    await init();
    final userEmail = await _getCurrentUserEmail();

    if (userEmail == null || userEmail.isEmpty) {
      print(
          '⚠️ LocalBookingService.deleteBooking: No user email, cannot delete');
      return;
    }

    final key = _getUserBookingKey(bookingId, userEmail);
    print(
        '🗑️ LocalBookingService.deleteBooking: Deleting booking with key = $key');
    await _box?.delete(key);
    print('✅ LocalBookingService.deleteBooking: Booking deleted successfully');
  }

  /// Clear all local bookings
  static Future<void> clearAll() async {
    await init();
    await _box?.clear();
  }
}
